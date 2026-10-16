# 0001 — Technology stack and hosting

- **Status:** Accepted. The content-format decision is superseded by
  [0002](0002-hand-curated-content-components.md).
- **Date:** 2026-10-15
- **Decider:** John Elrod (architect)
- **Author:** Claude (engineer)
- **Issue:** [#2](https://github.com/john-elrod/elrod.id/issues/2)

## Context

Elrod.id is a small portfolio site of static pages. The [design spec](../specs/2026-10-05-site-structure-design.md)
does not depend on any particular stack, but it does set requirements that the
stack has to meet:

- all content and navigation work without JavaScript (§6)
- Lighthouse mobile score ≥ 90 in every category (§6)
- content stored as structured records, separate from templates (§3.2)
- hosting, DNS and HTTPS defined in code in `/iac` (§7)
- CI on every pull request, and automatic production deploys from `main` (§7)

John set these constraints on 2026-10-15:

- **Framework:** Nuxt, built with Vite.
- **Design:** the design system lives in a `DESIGN.md` file, the Markdown
  format Google introduced with Stitch. It records
  colors, typography, spacing and component patterns, and it is applied at
  build time. Swapping to a different design template must be easy.
- **Testing:** front-end testing stays light.
- **Hosting:** Azure Static Web Apps, in John's existing Azure subscription
  and the existing resource group `elrod-id_group`.
- **DNS:** Azure DNS. The domain stays registered at GoDaddy.
- **Package manager:** pnpm.
- **Branching:** `main` is the only long-lived branch. Pull requests merge
  into `main`, and every merge to `main` deploys to production. **There are
  no PR preview deployments.** The spec's §7 was updated to match.

## Evaluation criteria

Issue #2 sets the criteria for every option: works without JavaScript,
Lighthouse mobile ≥ 90 is achievable, custom domain with automatic HTTPS,
IaC support, ongoing cost and maintenance effort. The issue also listed **PR
preview deployments**, but John has since removed that requirement, so the
comparisons below record it for information only.

## Decision summary

| Area | Decision |
|---|---|
| Framework | **Nuxt 4**, fully pre-rendered with `nuxt generate` (static site generation). Vite is Nuxt's built-in bundler. |
| Language | TypeScript and Vue single-file components |
| Styling | **Plain CSS with custom properties (design tokens)**, generated from `DESIGN.md` at build time. Each design template is a **Nuxt layer**. |
| Content format | ~~Nuxt Content v3 collections~~. **Superseded by [0002](0002-hand-curated-content-components.md):** hand-curated Vue content components, no data structure. |
| Runtime and package manager | **Node.js 24 LTS** and **pnpm**, with the pnpm version pinned in `package.json` (`packageManager`) |
| Hosting | **Azure Static Web Apps, Free plan**, region `westus2` (the resource group's location) |
| DNS | **Azure DNS** public zone `elrod.id`, delegated from GoDaddy. Registration stays at GoDaddy. |
| HTTPS | Static Web Apps' free managed certificates, which renew automatically |
| Infrastructure as code | **Bicep** in `/iac`, using Azure Verified Modules where one exists |
| CI/CD | **GitHub Actions** in `.github/workflows/`, signing in to Azure with OIDC (no stored Azure passwords) |
| Testing | The automated CI checks from spec §7 only. No unit-test or end-to-end test suites. |

## Options considered

### Site framework

| Criterion | **Nuxt 4 (SSG)** — chosen | Astro | Eleventy |
|---|---|---|---|
| Works without JS | Yes. Every route is pre-rendered to HTML. | Yes. Ships no JS by default. | Yes. Ships no JS at all. |
| Lighthouse mobile ≥ 90 | Achievable. The Vue runtime and hydration add some JS, so the budgets need watching. | Easiest | Easiest |
| Content model (§3.2) | Nuxt Content collections with schemas | Content collections with schemas | Data files, without schemas |
| Swappable design templates | Nuxt layers: a template is a layer that can be swapped | Possible, by convention | Possible, by convention |
| Custom domain, HTTPS, IaC, PR previews | Depends on the host, not the framework. All three produce static files that any static host serves. | Same | Same |
| Cost | Free, open source | Free, open source | Free, open source |
| Maintenance | Moderate: larger dependency tree, regular majors | Moderate | Low |
| Fit with John's preference | **Chosen by John** | — | — |

Nuxt ships more JavaScript than the other two. Two things keep that
manageable: pages are fully pre-rendered, and the CI Lighthouse budgets
(#19) catch regressions. Because the HTML is complete before any script
runs, the "works without JavaScript" requirement holds.

### Styling and design templates

`DESIGN.md` is the source of truth for the design. A build step reads its
tokens (colors, type scale, spacing, radii) and turns them into CSS custom
properties. Components use only those properties and never hard-code
values.

Each design template is a **Nuxt layer** (`layers/<template-name>/`)
that contains its `DESIGN.md`, its generated token CSS and any component
overrides. The active template is chosen in `nuxt.config.ts`
(`extends`), so swapping templates means changing one line and
rebuilding. Templates are swapped at build time only: the spec allows a
single dark theme and no theme switching at runtime.

| Option | Pros | Cons |
|---|---|---|
| **Plain CSS + custom properties** (recommended) | No extra dependency. Tokens map one-to-one from `DESIGN.md`. Full control over focus styles and contrast. | More hand-written CSS |
| Tailwind CSS v4 | Its `@theme` turns tokens into custom properties. AI tools often emit Tailwind from DESIGN.md. | Utility classes in the markup make swapping templates harder. Adds a dependency. |
| UnoCSS | Fast, flexible | Smaller community, another configuration language |

The chosen approach meets the spec's dark-only theme
(`color-scheme: dark`) and AA contrast: the build checks the token values,
and the accessibility scan in CI checks the rendered pages.

### Content format

> **Superseded by [0002](0002-hand-curated-content-components.md).**
> John chose hand-curated content components instead of structured
> records. The comparison below is kept for the record.

| Option | Pros | Cons |
|---|---|---|
| **Nuxt Content v3 collections** (recommended) | Schemas (zod) validate every project and role at build time. YAML and Markdown are easy to edit. Queries are built in. | Navigating between pages in the browser loads a small database the first time. The first page load is not affected. |
| JSON/YAML files imported directly | No dependency | No validation, and querying has to be written by hand |
| Headless CMS | Editing in a web UI | Hosting, cost and a runtime dependency are not justified for one author |

### Hosting

| Criterion | **Azure Static Web Apps (Free)** — chosen | Azure Storage static website + Front Door | GitHub Pages |
|---|---|---|---|
| Works without JS, Lighthouse ≥ 90 | Not affected. Serves static files from a global edge with compression. | Not affected | Not affected |
| Custom domain + automatic HTTPS | Yes. Free managed certificates, apex and `www`. | Yes, through Front Door | Yes. A `www`→apex redirect is limited. |
| Redirects and headers | `staticwebapp.config.json` (redirects, 404, security headers) | Front Door rules engine | None (no custom headers) |
| IaC support | Bicep, with Azure Verified Modules | Bicep | Not applicable |
| PR previews (no longer required) | Available (3 per app) | No | No |
| Monthly cost | $0 | Front Door Standard ≈ $35 plus traffic | $0 |
| Maintenance | Low | Medium | Low |
| Fits John's Azure estate | Yes | Yes | No |

**Free-plan limits:** 2 custom domains per app (`elrod.id` and
`www.elrod.id` use both), 250 MB maximum app size, and no SLA. The
Standard plan (about $9 a month) can be switched on later in the portal if
an SLA is ever needed.

### DNS

| Option | Pros | Cons |
|---|---|---|
| **Azure DNS, delegated from GoDaddy** (chosen) | Records live in Bicep. Supports the alias records Static Web Apps needs at the apex. One-time nameserver change. | About $0.50 a month per zone |
| GoDaddy DNS, managed by hand | No change | GoDaddy can't point the apex at Static Web Apps (no ALIAS, ANAME or CNAME flattening). Microsoft's custom-domain docs [name GoDaddy specifically](https://learn.microsoft.com/azure/static-web-apps/custom-domain) and recommend Azure DNS instead. Records would not be in code. |

The [delegation procedure](#bootstrap-delegating-dns-from-godaddy-to-azure)
is below.

### Infrastructure as code

| Option | Pros | Cons |
|---|---|---|
| **Bicep** (chosen) | Azure-native. Supports new resource types on day one. No state file to store or lock. Azure Verified Modules (AVM) for Static Web Apps and DNS zones. | Azure only |
| Terraform / OpenTofu | Multi-cloud, large ecosystem | Needs a remote state backend. Provider support for new Azure features can lag. |
| Pulumi | Real programming languages | Needs a state backend. More moving parts than a site this size needs. |

Bicep deploys at resource-group scope into `elrod-id_group`. The
subscription ID and resource group name live in GitHub Actions variables,
not in the repository.

### CI/CD

GitHub Actions, with workflows in `.github/workflows/` (the location
GitHub requires).

- **CI** runs on every pull request to `main` and every push to `main`:
  install, build, lint and format check, HTML validation, internal link
  check, axe accessibility scan, and Lighthouse CI against the spec §6
  budgets. Details are in #19.
- **CD** runs on a push to `main` once CI has passed. It builds with pnpm
  and uploads the pre-built `.output/public` folder with
  `Azure/static-web-apps-deploy` (`skip_app_build: true`), so Azure's own
  build system is not used. Details are in #20.
- **Azure sign-in:** an Entra ID app registration with a federated
  credential for this repository's `main` branch (OIDC). The workflow
  signs in with `azure/login` and reads the Static Web Apps deployment
  token at run time. No long-lived Azure secret is stored in GitHub.
- **Infrastructure changes** (`iac/**`) are applied by a workflow on
  `main` with the same OIDC identity, after a `what-if` preview in the
  pull request.

### Testing

John asked for light front-end testing. The spec §7 CI checks stay,
because they are automated and need no ongoing upkeep: build, lint, HTML
validation, link check, axe and Lighthouse. Unit-test and end-to-end test
suites are not added. The manual checks in spec §8 (responsive widths,
keyboard, screen reader, JavaScript off) are still done for each page
issue.

## Bootstrap: delegating DNS from GoDaddy to Azure

`elrod.id` stays **registered** at GoDaddy, where renewal and billing
continue. Only the **nameservers** change, so that Azure DNS answers for
the domain. This is a one-time manual step, done during #18.

1. **List the existing records.** In GoDaddy, open *My Products → elrod.id
   → DNS* and note every record that must keep working, especially
   **MX**, **TXT** (SPF, DKIM, DMARC, site verifications) and any
   **CNAME**s. After the switch, records in GoDaddy's DNS panel stop
   having any effect.
2. **Create the Azure DNS zone with those records.** The Bicep in
   `/iac` creates the `elrod.id` zone in `elrod-id_group`. Any records from
   step 1 are added to it first, so nothing breaks at cutover. Then list
   the zone's four nameservers:
   ```bash
   az network dns zone show -g elrod-id_group -n elrod.id --query nameServers -o tsv
   ```
3. **Check DNSSEC.** If DNSSEC is turned on at GoDaddy, turn it off and
   wait for the DS record to expire before changing nameservers. A stale
   DS record would make the domain fail to resolve.
4. **Change the nameservers at GoDaddy.** Go to *Domain → DNS →
   Nameservers → Change nameservers → "I'll use my own nameservers"*,
   enter the four Azure nameservers (no trailing dot), and save.
5. **Verify.** The change can take up to 48 hours to spread:
   ```bash
   nslookup -type=NS elrod.id 8.8.8.8
   ```
   The answer should list the `*.azure-dns.*` nameservers.
6. **Bind the custom domains.** Add `elrod.id` (apex, alias record) and
   `www.elrod.id` (CNAME) to the static web app, then set `elrod.id` as
   the **default domain** so that `www` redirects to it. #18 confirms
   that this redirect returns a 301 and preserves the path, as its
   acceptance criteria require.

## Local toolchain

The development machine needs these tools. They are installed when work
begins on #5 (site shell) and #18 (IaC).

| Tool | Status on 2026-10-15 | Action |
|---|---|---|
| Node.js | 20.19.6. Too old: Nuxt 4.6 needs ^22.22.3, ^24.15.0 or ≥ 26. Node 20 is past end of life. | Install Node 24 LTS: `winget install OpenJS.NodeJS.LTS` |
| pnpm | Not installed | `corepack enable pnpm` (from an elevated shell), or `npm install -g pnpm` |
| Azure CLI | Installed, updates available | `az upgrade` |
| Bicep | 0.45.6, through Azure CLI | `az bicep upgrade` |
| GitHub CLI | Installed | — |

## Consequences

- Build, test and run commands are recorded in `CLAUDE.md` once #5
  scaffolds the project.
- #18 builds the Static Web App, the Azure DNS zone and records, the custom
  domains and the default-domain redirect in Bicep. Delegating DNS is its
  documented bootstrap step.
- #20 drops PR previews. Production deploys run on merges to `main` only.
- Expected running cost is about **$0.50–$1 a month** (the Azure DNS zone
  and its queries). Static Web Apps Free costs nothing. Domain renewal
  stays with GoDaddy.
- Nuxt ships more JavaScript than Astro or Eleventy would. The Lighthouse
  budgets in CI (#19) guard against regressions.
- The Free plan has no SLA, which is acceptable for a personal portfolio.
