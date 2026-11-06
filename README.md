# elrod.id

A career portfolio web site for John Elrod, built with Nuxt 4 (static
generation) and hosted on Azure Static Web Apps.

## Requirements

- Node.js 24 LTS
- pnpm 12 (the exact version is pinned in `src/package.json`)

## Commands

Run these from the `src/` folder.

| Command | What it does |
|---|---|
| `pnpm install` | Install dependencies |
| `pnpm dev` | Start the dev server at `http://localhost:3000` |
| `pnpm generate` | Build the static site into `src/.output/public` (`pnpm build` is an alias) |
| `pnpm preview` | Serve the built site locally |

## Documentation

- [Design spec](docs/specs/2026-10-05-site-structure-design.md)
- [Decision records](docs/decisions/)
- [Deployment](docs/deployment.md): Azure resources, the GitHub Actions
  workflow and how to check a deploy
