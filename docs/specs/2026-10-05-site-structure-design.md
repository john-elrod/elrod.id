# Elrod.id — Site Structure & Layout Design

- **Date:** 2026-10-05
- **Status:** Draft — awaiting architect review
- **Architect / PM / Stakeholder:** John Elrod
- **Engineer / Technical Writer / Tester:** Claude

## 1. Purpose

Elrod.id is John Elrod's personal website. It is a career portfolio that
accompanies his résumé, with room to grow into other information about him.

**Audience (in priority order):**

1. Recruiters and hiring managers — arrive from the résumé or LinkedIn; need to
   verify experience quickly and make contact.
2. Prospective clients — evaluate past work in depth.
3. Professional network and general visitors — want to know who John is.

**Success for v1:** a visitor on a phone can, within about 30 seconds of
landing, understand who John is, see representative work, download the
résumé, and find a way to get in touch.

## 2. Scope

**In v1:** Home (including About and Contact sections), Projects index,
Project detail, Experience, 404, a dark theme, CI/CD, and deployment
to `https://elrod.id`.

**Deferred to Backlog:** Writing/Blog, contact form, project tag filtering,
additional "about me" sections, analytics.

**Out of scope for this document:** technology stack selection. It is
tracked as its own decision issue; this design is stack-agnostic.

## 3. Sitemap

Organization: **hybrid** — a scannable summary home page plus dedicated
pages for depth, with stable per-project URLs suitable for citing on the
résumé.

```
elrod.id/
├── /                     Home: Hero → Featured projects → Recent experience → #about → #contact
├── /projects             Projects index
│   └── /projects/<slug>  Project detail
├── /experience           Experience timeline + résumé PDF download
└── /404                  Not found
```

### 3.1 Pages

| Page | Job | Contents |
|---|---|---|
| Home `/` | Answer "who is John and should I keep reading?" in ~30 s | Hero (name, headline, value statement, optional photo, Résumé and Contact buttons); 2–3 featured projects; 3 most recent roles with a link to `/experience`; `#about` section; `#contact` section |
| Home `#about` | The person behind the résumé | Bio, headshot, interests/values |
| Home `#contact` | Make contact easy | Obfuscated email link, LinkedIn, GitHub. No form in v1 |
| Projects `/projects` | Browse all work | Responsive grid of cards: title, one-line summary, role, year, tags |
| Project detail `/projects/<slug>` | Citable deep link for one project | Summary, role, problem, approach, outcome/impact, tech/skills, links (live, repo), images, previous/next navigation |
| Experience `/experience` | Expand on the résumé | Reverse-chronological roles (company, title, dates, highlights), skills summary, education and certifications, résumé PDF download |
| 404 | Recover from bad links | Short message with links to Home and Projects |

### 3.2 Content model

Content is stored as structured records separate from page templates.
Adding a project or role means adding a record, not editing layout code.
The storage format is chosen with the stack.

- **Project:** `slug`, `title`, `summary`, `role`, `year`, `tags[]`,
  `featured` (bool), `problem`, `approach`, `outcome`, `tech[]`,
  `links[]` (label, url), `images[]` (src, alt), `order`.
- **Role:** `company`, `title`, `start`, `end` (or present), `location`,
  `highlights[]`, `order`.
- **Site profile:** `name`, `headline`, `valueStatement`, `bio`,
  `headshot` (src, alt), `email`, `social[]` (label, url),
  `resumePdf`.

Home "featured projects" are the projects with `featured: true`, ordered by
`order`. Home "recent experience" is the first three roles by date.

## 4. Layout

### 4.1 Global shell (every page)

- **Header:** "John Elrod" wordmark (links to `/`), primary nav.
- **Primary nav:** Projects (`/projects`), Experience (`/experience`),
  About (`/#about`), Contact (`/#contact`). The anchor links work from any
  page. On the home page they scroll smoothly to the section, or jump
  instantly when the visitor has turned on reduced motion.
- **Main:** a single `<main>` landmark preceded by a "Skip to content" link.
- **Footer:** email, LinkedIn, GitHub, résumé PDF download, © year.

### 4.2 Responsive behavior (mobile-first)

Base styles target phones. Breakpoints only add enhancements.

| Breakpoint | Min width | Behavior |
|---|---|---|
| Base | 0 | Single column; nav collapsed behind a menu button opening a full-width panel; stacked cards; tap targets ≥ 44×44 px |
| Tablet | 640 px | 2-column project grid; hero may place text and photo side by side |
| Desktop | 1024 px | Inline nav (no menu button); 3-column project grid; body text max ~70ch; content container max width capped |

### 4.3 Home wireframe

```
PHONE                         DESKTOP
┌──────────────────┐          ┌───────────────────────────────────────────────┐
│ John Elrod     ☰ │          │ John Elrod   Projects Experience About Contact │
├──────────────────┤          ├───────────────────────────────────────────────┤
│ [photo]          │          │  Headline + value statement          [photo]  │
│ Headline         │          │  [Résumé] [Contact]                           │
│ [Résumé][Contact]│          ├───────────────────────────────────────────────┤
├──────────────────┤          │  Featured: [card] [card] [card]               │
│ Featured  [card] │          ├───────────────────────────────────────────────┤
│           [card] │          │  Recent experience (3 roles) → all            │
├──────────────────┤          ├───────────────────────────────────────────────┤
│ Recent roles     │          │  #about    bio + interests                    │
├──────────────────┤          ├───────────────────────────────────────────────┤
│ #about           │          │  #contact  email · LinkedIn · GitHub          │
│ #contact         │          ├───────────────────────────────────────────────┤
├──────────────────┤          │  footer                                       │
│ footer           │          └───────────────────────────────────────────────┘
└──────────────────┘
```

## 5. Theme

- **Dark only.** The site has a single dark theme. There is no light
  theme, no theme toggle, and no time-of-day or device-preference
  switching.
- The page declares `color-scheme: dark`, so the browser draws its own
  controls and scrollbars dark as well.
- The theme is pure CSS and needs no JavaScript.
- The palette must meet WCAG 2.1 AA contrast.

## 6. Cross-cutting requirements

These apply to every page and are included in each issue's acceptance
criteria.

- **Accessibility:** WCAG 2.1 AA; full keyboard operability with a visible
  focus indicator; semantic landmarks and heading order; descriptive
  alt text; respects `prefers-reduced-motion`.
- **Performance:** Lighthouse mobile score ≥ 90 in Performance,
  Accessibility, Best Practices and SEO. Images responsive, correctly sized
  and lazy-loaded below the fold.
- **SEO and sharing:** unique `<title>` and meta description per page;
  Open Graph and Twitter card tags; `sitemap.xml`; `robots.txt`; canonical
  URLs on `https://elrod.id`.
- **Works without JavaScript:** all content and navigation work without
  scripts. Only the menu animation needs JavaScript; with
  JavaScript off, the mobile menu still opens using a no-JS fallback
  (e.g. `<details>` or `:target`).
- **Privacy:** no tracking or third-party cookies in v1. The email address
  is obfuscated against scrapers.
- **Browser support:** latest two versions of Chrome, Edge, Firefox and
  Safari, plus iOS Safari and Android Chrome.

## 7. Delivery: CI/CD and infrastructure

- **Infrastructure as code (`/iac`):** hosting, DNS for `elrod.id`
  (including `www` redirecting to the bare domain) and HTTPS certificates
  are defined in code.
- **CI (every pull request):** build, lint/format check, HTML validation,
  broken-link check, automated accessibility scan, and Lighthouse budgets
  matching §6. All checks are required before merge.
- **CD:** `main` is the only long-lived branch. Pull requests merge into
  `main`, and merging to `main` deploys to production automatically once
  CI passes. There are no pull request preview deployments. A documented
  rollback procedure is required.
- **Repository workflow:** `main` is protected (pull request required,
  CI must pass), with a pull request template that includes the testing
  checklist.

## 8. Testing approach

Claude, as tester, owns verification:

- Every issue carries acceptance criteria written as a checklist; an issue
  closes only when every item has been checked and the evidence noted in
  the PR.
- Automated: the CI checks listed in §7.
- Manual: a responsive pass at 360, 768 and 1280 px wide; a keyboard-only
  pass; a screen-reader spot check; JavaScript disabled.

## 9. GitHub issue plan

> **Snapshot only.** This is the initial issue breakdown as of 2026-10-05.
> [GitHub Issues](https://github.com/john-elrod/elrod.id/issues) is
> the system of record for all work items. This table is not maintained
> after the issues are filed, and the `#` column is a planning number, not
> the GitHub issue number.

**Milestones:** `v1`, `Backlog`.
**Labels:** existing `enhancement`, `documentation`, `accessibility`; new
`page`, `layout`, `content`, `infrastructure`.

Each issue contains a user story, acceptance criteria, and dependencies.

### v1

| # | Issue | Labels | Depends on |
|---|---|---|---|
| 1 | Decide technology stack and hosting (decision record) | documentation | — |
| 2 | Define content model for projects, roles, and site profile | content | 1 |
| 3 | Design basics: type scale, spacing, dark color palette | layout, accessibility | — |
| 4 | Site shell: header, footer, skip link, main landmark | layout | 1, 3 |
| 5 | Responsive navigation: mobile menu, desktop inline nav, cross-page anchors | layout, accessibility | 4 |
| 6 | Home page: hero, featured projects, recent experience | page | 2, 4 |
| 7 | Home page: `#about` section | page | 6 |
| 8 | Home page: `#contact` section | page | 6 |
| 9 | Projects index page | page | 2, 4 |
| 10 | Project detail page | page | 9 |
| 11 | Experience page | page | 2, 4 |
| 12 | Résumé PDF download | enhancement | 11 |
| 13 | 404 page | page | 4 |
| 14 | SEO and social sharing metadata | enhancement | 4 |
| 15 | Accessibility baseline and audit | accessibility | 6–13 |
| 16 | Performance baseline | enhancement | 6–13 |
| 17 | Infrastructure as code: hosting, DNS, HTTPS for elrod.id | infrastructure | 1 |
| 18 | CI pipeline: build, lint, validation, link, a11y, Lighthouse checks | infrastructure | 1 |
| 19 | CD pipeline: production deploy on `main`, PR previews, rollback | infrastructure | 17, 18 |
| 20 | Branch protection and pull request workflow | infrastructure, documentation | 18 |
| 21 | Initial content: bio, headshot, projects, roles, résumé PDF (owner: John) | content | 2 |

### Backlog

| Issue | Labels |
|---|---|
| Writing / Blog section | page |
| Contact form | enhancement |
| Project tag filtering | enhancement |
| Additional "about me" sections | page, content |
| Privacy-friendly analytics | enhancement |
