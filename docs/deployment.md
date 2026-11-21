# Deployment

How the site is built and hosted today. #18 (infrastructure as code) and
#20 (production deploy, rollback) will extend this document.

## Azure resources

The static web app was created by hand in the Azure portal and is not yet
defined in Bicep (#18).

| Item | Value |
|---|---|
| Subscription | Ninja Azure Subscription (`b9d9e1c6-b2ab-4e1d-93d0-9673867b5ed8`) |
| Resource group | `elrod-id_group` (`westus2`) |
| Static web app | `elrod-id-website` |
| Plan | Free |
| Region | East US 2 (`eastus2`) |
| Default hostname | `salmon-sea-04187ca0f.5.azurestaticapps.net` |
| Linked repository | `john-elrod/elrod.id`, branch `main` |
| Custom domains | None yet (#18) |

The static web app is in East US 2 by John's decision, recorded in 0001. The
resource group is in `westus2`, and the two regions do not have to match.
Static Web Apps does not offer plain "East US". Its regions are West US 2,
Central US, East US 2, West Europe and East Asia. #18 must set `eastus2` in
Bicep so a redeploy does not move the app.

## GitHub Actions workflow

[`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) replaced
the file the Azure portal generated. That file used Azure's own build (Oryx)
and PR previews, and it failed on the first run because the repository had
no `package.json`. The current workflow follows decision record 0001:

- **Pull requests to `main`:** install and `pnpm generate` only. Nothing is
  deployed, and there are no preview environments.
- **Pushes to `main`:** the same build, then the `src/.output/public`
  artifact is uploaded with `Azure/static-web-apps-deploy` and
  `skip_app_build: true`.
- Node 24, with the pnpm version taken from `packageManager` in
  `src/package.json`.

### Deployment authorization policy: GitHub ID token required

The static web app's `deploymentAuthPolicy` is `GitHub`, the default when
the portal links a GitHub repository. With that policy Azure accepts a
deploy only if it carries a GitHub OIDC ID token as well as the deployment
token. The deploy job therefore has `id-token: write` (that job only), gets
the token with `actions/github-script`, and passes it to
`Azure/static-web-apps-deploy` as `github_id_token`.

Without the ID token, the deploy step fails with *"No matching Static Web
App was found or the api key was invalid"*, even when the deployment token
is correct. Resetting the token does not fix that error (#37). To check
the policy:

```bash
az rest --method get --url "https://management.azure.com/subscriptions/b9d9e1c6-b2ab-4e1d-93d0-9673867b5ed8/resourceGroups/elrod-id_group/providers/Microsoft.Web/staticSites/elrod-id-website?api-version=2024-04-01" \
  --query properties.deploymentAuthPolicy -o tsv
```

### Interim: deployment token secret

Record 0001 calls for OIDC sign-in with no stored Azure secret. That is not
set up yet. For now, the deploy step uses the Static Web Apps deployment
token that the portal stored as the GitHub Actions repository secret
`AZURE_STATIC_WEB_APPS_API_TOKEN_SALMON_SEA_04187CA0F`. #20 replaces it with
OIDC. To rotate the token, reset it in the portal (*Static web app →
Overview → Manage deployment token*) and update the secret.

## Checking a deploy

```bash
# Latest workflow runs
gh run list --repo john-elrod/elrod.id --limit 5

# Environment status. "Ready" means content is live.
az staticwebapp environment list -n elrod-id-website -g elrod-id_group \
  --query "[].{name:name,status:status,hostname:hostname}" -o table

# Fetch the live page
curl -s https://salmon-sea-04187ca0f.5.azurestaticapps.net/
```
