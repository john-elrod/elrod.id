# Infrastructure

How hosting, DNS and HTTPS for `https://elrod.id` are defined in code, how
to preview and apply a change, the one-time bootstrap steps, and what it
costs. The choices behind this are in
[decision record 0001](decisions/0001-technology-stack-and-hosting.md). How
the site is built and deployed is in [deployment.md](deployment.md).

## What is defined

Everything is in [`iac/main.bicep`](../iac/main.bicep), with the production
values in [`iac/main.bicepparam`](../iac/main.bicepparam). It deploys at
resource-group scope into `elrod-id_group`.

| Resource | Notes |
|---|---|
| Static web app `elrod-id-website` | Free plan, East US 2. **Adopted**: it was created in the portal, and the template restates its current settings. |
| Azure DNS zone `elrod.id` | Public zone. Its four nameservers are an output of the deployment. |
| `A` record `@` | Alias to the static web app. No IP address is written down. |
| `CNAME` record `www` | The static web app's default hostname. |
| `MX` records `@` | Google Workspace, copied unchanged from GoDaddy. |
| `TXT` records `@` | SPF, and the ownership token Static Web Apps checked when the apex was bound. Copied unchanged from GoDaddy. |
| `TXT` record `dc-aa8e722993._spfm` | The SPF include target. Copied unchanged from GoDaddy. |
| Custom domains `elrod.id` and `www.elrod.id` | Bound to the static web app. |
| TLS certificates | Not a resource. Static Web Apps issues a free managed certificate for each bound custom domain and renews it automatically, as long as the domain keeps resolving to the app over public DNS. |

I used plain Bicep resources rather than Azure Verified Modules. The
template is about 10 resources, and adopting an app that already exists
needs exact control over which properties are sent. An AVM static-site
module sets its own defaults, so it could change the live app.

### Not in the template (manual, one time)

| Step | Why it cannot be code |
|---|---|
| Change the nameservers at GoDaddy | The registrar has no API in this repository's toolchain, and only John has the account. |
| Set `elrod.id` as the static web app's **default domain** | This is what makes `www.elrod.id` redirect to `elrod.id`. The setting is shown by the API (`isDefault` on the custom domain) but it is not in any published Static Web Apps API version or Bicep type, so it cannot be written from Bicep. It is a portal action. |

## Secrets and credentials

No secret is stored in the repository. The template has no secret
parameters, and `repositoryToken` is deliberately not set.

| Secret | Where it lives |
|---|---|
| Static Web Apps deployment token | In Azure (*Static web app → Overview → Manage deployment token*) and as the GitHub Actions repository secret `AZURE_STATIC_WEB_APPS_API_TOKEN_SALMON_SEA_04187CA0F`. See [deployment.md](deployment.md). #20 replaces it with OIDC. |
| Azure access for `az deployment` | John's own `az login` session. Nothing is stored. |
| GoDaddy account | John's GoDaddy login. Not shared with Claude or CI. |

DNS records are public by nature, so they appear in the template. The
`_yg07rdq8n1fo0jxxrxho2qxvistv35p` TXT value is a public ownership check
that is visible to anyone querying DNS, not a secret.

## Plan and apply

Needs the Azure CLI (it installs Bicep: `az bicep install`) and the
Contributor role on `elrod-id_group`. Run from `iac/`.

```bash
az login
az account set --subscription "Ninja Azure Subscription"

# 1. Compile. Catches syntax errors and warnings.
az bicep build --file main.bicep --stdout > /dev/null

# 2. Validate against Azure. Creates nothing.
az deployment group validate -g elrod-id_group -f main.bicep -p main.bicepparam

# 3. Plan: preview what would change. Creates nothing.
az deployment group what-if -g elrod-id_group -f main.bicep -p main.bicepparam

# 4. Apply. Only after reading the plan.
az deployment group create -g elrod-id_group -n iac -f main.bicep -p main.bicepparam

# The nameservers, for the GoDaddy step
az deployment group show -g elrod-id_group -n iac --query properties.outputs.nameServers.value -o tsv
```

Changes to `iac/` go through a pull request like any other change. John
approves the plan before anything is applied. A workflow that previews
and applies `iac/` changes from GitHub is a separate piece of work (CD,
#20).

### Reading the plan

The plan is expected to show a few changes that are not real, because
Azure does not return some properties. Ignore these:

- `staticSites/elrod-id-website`: removal of `stableInboundIP` and
  `trafficSplitting`. Both are read-only.
- `customDomains/elrod.id`: removal of `expiresOn` and `isDefault`
  (read-only), and addition of `validationMethod` (write-only, so Azure
  never returns it). The same `validationMethod` addition shows for
  `www.elrod.id` on every run.

Anything else on the static web app (SKU, region, repository, branch)
would be a real change. Stop and ask before applying it.

### Idempotence

Applying the same template again changes nothing: Bicep deployments are
incremental, every resource is declared with fixed values, and the DNS
records are set, not appended. To check, apply twice and compare the
resource snapshot (below) and `az deployment group what-if`, which should
list only the noise above.

### Snapshot the static web app before the first apply

The static web app already exists, and `az deployment group create` sends
it a full `PUT`. Take a snapshot before and after the first apply, and
confirm that nothing but timestamps changed:

```bash
az rest --method get --url "https://management.azure.com/subscriptions/b9d9e1c6-b2ab-4e1d-93d0-9673867b5ed8/resourceGroups/elrod-id_group/providers/Microsoft.Web/staticSites/elrod-id-website?api-version=2024-11-01" > swa-before.json
# ... apply ...
az rest --method get --url "<same URL>" > swa-after.json
diff swa-before.json swa-after.json   # expect no output
```

Also confirm that the next push to `main` still deploys (see *Checking a
deploy* in [deployment.md](deployment.md)). If the apply changes the app
(for example it unlinks the repository), change `staticWebApp` in
`main.bicep` to an `existing` reference and drop its properties, so that
the template only manages DNS and the custom domains.

## Bootstrap (first apply, from today's state)

Today `elrod.id` is registered at GoDaddy and **GoDaddy also hosts its DNS**
(`ns55.domaincontrol.com`, `ns56.domaincontrol.com`). The apex is bound to
the static web app by an `A` record and a TXT token at GoDaddy, and the site
already serves over HTTPS. `www` is a CNAME at GoDaddy but is **not** bound
to the static web app yet. The steps below move DNS to Azure without an
outage. They follow the
[delegation procedure in 0001](decisions/0001-technology-stack-and-hosting.md#bootstrap-delegating-dns-from-godaddy-to-azure).

1. **Confirm the record list.** In GoDaddy open *My Products → elrod.id →
   DNS* and compare it with the table above. Records seen in public DNS on
   2026-11-20: `A @` 20.22.16.164, `CNAME www`, five Google `MX`, two `TXT @`,
   and `TXT dc-aa8e722993._spfm`. DNS cannot list a whole zone, so anything
   else in the GoDaddy panel (DKIM, DMARC, verification records, other
   subdomains) must be added to `main.bicep` before cutover. Mail stops if
   an MX or DKIM record is missing.
2. **Apply** (see above). This creates the zone and records, binds
   `www.elrod.id` (it validates against the CNAME that GoDaddy already
   serves), and re-affirms the apex binding. Azure DNS is not yet in use, so
   nothing changes for visitors.
3. **Check the new zone answers correctly**, by asking Azure's nameservers
   directly, before delegating:
   ```bash
   az network dns zone show -g elrod-id_group -n elrod.id --query nameServers -o tsv
   nslookup elrod.id <one-azure-nameserver>
   nslookup -type=MX elrod.id <one-azure-nameserver>
   nslookup -type=TXT elrod.id <one-azure-nameserver>
   nslookup www.elrod.id <one-azure-nameserver>
   ```
4. **DNSSEC.** As of 2026-11-20 the `.id` registry has no DS record for
   `elrod.id`, so DNSSEC is off and nothing needs to be disabled. Re-check
   with `nslookup -type=DS elrod.id 8.8.8.8` right before the change.
5. **Change the nameservers at GoDaddy** (John): *Domain → DNS →
   Nameservers → Change nameservers → "I'll use my own nameservers"*, enter
   the four Azure nameservers without a trailing dot, and save. To roll
   back, set them back to `ns55.domaincontrol.com` and
   `ns56.domaincontrol.com`.
6. **Verify delegation** (up to 48 hours):
   ```bash
   nslookup -type=NS elrod.id 8.8.8.8     # expect *.azure-dns.* names
   ```
7. **Set the default domain** (John, portal): *Static web app
   `elrod-id-website` → Custom domains →* `elrod.id` *→ Set default*.
8. **Verify** the redirects and certificates:
   ```bash
   curl -sI http://elrod.id/some/path          # 301 -> https://elrod.id/some/path
   curl -sI https://www.elrod.id/some/path     # 301 -> https://elrod.id/some/path
   curl -sIL http://www.elrod.id/some/path     # redirect chain should end at https://elrod.id/some/path
   curl -sI https://elrod.id/                  # 200, certificate valid
   ```
   GoDaddy's DNS panel has no effect after step 5. Leave its records in
   place for a week as a fallback, then clean up.

### Rebuilding from nothing

If the static web app, the zone or both are lost: run the plan and apply
steps with `-p bindCustomDomains=false` first (the apex validation token
cannot be written until the app exists), add the TXT token Azure shows in
*Custom domains* to the zone, then apply again with `bindCustomDomains=true`.
Then redo the GoDaddy nameserver and default-domain steps if the zone is new
(a new zone gets new nameservers).

## Redirects

| Redirect | Provided by |
|---|---|
| `http://` to `https://`, 301, path preserved | Static Web Apps, built in for every custom domain. Nothing to configure. |
| `www.elrod.id` to `https://elrod.id` | The static web app's default domain (manual step 7). `staticwebapp.config.json` cannot do this: its rules cannot match on the host name. |

## Expected monthly cost

| Item | Cost |
|---|---|
| Static Web Apps, Free plan | $0 |
| Managed TLS certificates | $0 |
| Azure DNS zone | $0.50 per zone per month |
| Azure DNS queries | $0.40 per million queries. A personal site makes well under a million a month, so about $0.01 or less. |
| **Total** | **About $0.50 to $0.55 a month** |

Prices are the Azure retail rates for public zones as of 2026-11-20
(from the [Azure retail prices API](https://prices.azure.com/api/retail/prices)).
Domain renewal stays with GoDaddy and is not included. Free-plan limits: 2
custom domains (both are used), 250 MB app size, no SLA.
