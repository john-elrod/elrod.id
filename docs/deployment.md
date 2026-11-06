# Deployment

How the site is built and hosted today. #18 (infrastructure as code) and
#20 (production deploy, rollback) will extend this document.

## Azure resources

The static web app was created by hand in the Azure portal and is not yet
defined in Bicep (#18).

| Item | Value |
|---|---|
| Subscription | Ninja Azure Subscription (`b9d9e1c6-b2ab-4e1d-93d0-9673867b5ed8`) |
| Resource group | `elrod-id_group` |
| Static web app | `elrod-id-website` |
| Plan | Free |
| Region | East US 2 |
| Default hostname | `salmon-sea-04187ca0f.5.azurestaticapps.net` |
| Linked repository | `john-elrod/elrod.id`, branch `main` |
| Custom domains | None yet (#18) |

Decision record 0001 expected `westus2`. The portal placed the app in East US
2 instead. Static Web Apps is a global service, and the region only
sets where its management data lives, so this does not affect visitors.

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
