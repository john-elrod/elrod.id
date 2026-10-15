# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Elrod.id (`https://elrod.id`) is John Elrod's personal website: a career
portfolio that accompanies his résumé. It is built **mobile-first** and is
responsive up to full desktop width.

- **Design spec:** [docs/specs/2026-10-05-site-structure-design.md](docs/specs/2026-10-05-site-structure-design.md)
  covers the sitemap, layout, breakpoints, theming, site-wide quality
  requirements and CI/CD.
- **Work items:** [GitHub Issues](https://github.com/john-league-ninja/elrod.id/issues)
  is the system of record. The issue table in the spec is a historical
  snapshot. Do not update it.
- **Technology stack:** decided in
  [docs/decisions/0001-technology-stack-and-hosting.md](docs/decisions/0001-technology-stack-and-hosting.md):
  Nuxt 4 (static generation, Vite) with TypeScript, plain CSS design
  tokens generated from `DESIGN.md` (each design template is a Nuxt layer),
  Nuxt Content for the content model, Node.js 24 LTS and pnpm. Hosting is
  Azure Static Web Apps (Free plan) with Azure DNS, IaC is Bicep in
  `iac/`, and CI/CD runs on GitHub Actions in `.github/workflows/`. Don't
  add other frameworks or tooling without a new decision record. Record
  the build, test and run commands here once the site shell (#5) exists.

## Roles

- **John Elrod:** architect, project manager and stakeholder. He makes
  architecture and scope decisions, and he reviews and merges every PR.
- **Claude:** engineer, technical writer and tester. Claude implements
  issues, writes the documentation, and verifies the acceptance criteria.

When an issue needs a decision the spec doesn't settle (stack, hosting,
visual design, scope changes), present options with a recommendation and
wait for John's decision. Don't choose for him.

## Repository layout

| Path | Contents |
|---|---|
| `src/` | Site source |
| `docs/` | Specs, decision records, technical documentation |
| `iac/` | Infrastructure as code (hosting, DNS, HTTPS) |
| `extras/` | Miscellaneous files |
| `.claude/skills/` | Project skills (see below) |

## Workflow

- **Never commit directly to `main`.** Every change goes on a branch and
  reaches `main` through a pull request that John reviews and merges.
  Claude never merges PRs.
- **One issue per branch.** Name branches `<type>/<issue#>-<short-slug>`,
  e.g. `feat/7-home-hero`, `fix/31-nav-focus`, `docs/1-stack-decision`.
  Types: `feat`, `fix`, `docs`, `chore`, `ci`, `infra`.
- **Commit messages:** imperative subject line (≤ 72 chars) and a
  reference to the issue, e.g. `Add home page hero (#7)`.
- **PR body** starts with `Closes #<n>`, then gives the acceptance
  criteria checklist, each item with the evidence that it was verified.
- **Stay in scope.** Work you find that is outside the issue becomes a new
  issue. It does not go into the current PR.

## Project skills

- `creating-github-issues`: use when John asks to create, file or log an
  issue, bug, feature or backlog item.
- `working-github-issues`: use when John asks to work, implement or pick
  up a GitHub issue. It ends with a PR to `main`.

## Site-wide requirements (summary — the spec is authoritative)

- Mobile-first breakpoints: base < 640 px, tablet ≥ 640 px, desktop ≥ 1024 px.
- WCAG 2.1 AA: keyboard operable, visible focus, AA contrast in both
  palette, honors `prefers-reduced-motion`. Tap targets at least 44 px.
- Dark theme only. There is no light theme and no theme toggle; the
  page declares `color-scheme: dark`.
- All content and navigation work without JavaScript.
- Lighthouse mobile score ≥ 90 in every category.
- No tracking or third-party cookies.

## Environment

- Development happens on Windows. The Bash tool runs Git Bash, and
  PowerShell is also available.
- GitHub access uses the `gh` CLI, authenticated as `john-league-ninja`.
  Repository: `john-league-ninja/elrod.id`.
- To pass multi-line text to `gh` (issue and PR bodies), write it to a
  temporary file outside the repo and use `--body-file`. Don't inline it
  in the shell.
