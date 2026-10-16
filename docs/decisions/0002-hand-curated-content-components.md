# 0002 — Hand-curated content components

- **Status:** Accepted. John approves it by merging the pull request that adds this record.
- **Date:** 2026-10-15
- **Decider:** John Elrod (architect)
- **Author:** Claude (engineer)
- **Issue:** [#31](https://github.com/john-elrod/elrod.id/issues/31)
- **Supersedes:** the content-format decision in [0001](0001-technology-stack-and-hosting.md#content-format)

## Context

[Decision record 0001](0001-technology-stack-and-hosting.md) chose Nuxt
Content collections, which store projects, roles and the site profile as
structured YAML records that are validated against schemas. Templates
would then generate pages and lists from those records. Spec §3.2 defined
the record fields.

On 2026-10-15 John decided against that approach. Each page's content is
to be written in a component that the page template pulls in, with no
defined data structure. All content is hand-curated, including Home's
featured projects and recent experience.

## Decision

Each page's content is hand-written in its own **content component**
(a Vue single-file component). The active design template renders it.

- **One content component per page:** Home, Projects index, Experience,
  404, and one for each project at `/projects/<slug>`.
- **Shared content components** hold content that appears on every page,
  such as the footer links.
- **Templates hold no content.** A design layer provides the page
  layouts and styled **building blocks** (for example a hero, a project
  card, a role entry). Content components are built from those building
  blocks.
- **Lists are written by hand:** featured projects, recent experience,
  the Projects index cards and each project's previous/next links.
- **Nuxt Content is not used**, and nothing replaces it. Content is
  ordinary Vue markup in the repository.

Where the content components live, and how a template pulls one in, are
settled when the components are implemented in #3.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **Hand-curated content components** (chosen) | Full control over every word and every list. No schemas or queries to learn. One less dependency. Content does not change when the design template does. | A project's title and summary are written twice (card and detail page). Nothing at build time checks that they match. |
| Content components with a small metadata block per project (title, summary, year, featured) | Cards are generated, so summaries are written once | Brings back a light data structure, which John does not want |
| Structured records with Nuxt Content (0001's original choice) | Schemas validate content. Lists are generated. | Content is split between data files and templates. Adds a dependency, and loads a small database in the browser when navigating between pages. |

## Consequences

- **Building blocks become the contract between content and design.**
  Every design layer must provide the same set of building-block
  components, with the same names and props, so that content components
  keep working when the template is swapped. #3 documents that set.
- **Review replaces validation.** No build step checks content. Keeping a
  project's card and detail page consistent is part of reviewing the
  pull request.
- **Spec §3.2** now describes content components instead of records.
  `CLAUDE.md` no longer names Nuxt Content.
- **Order of work changes.** Content components need a Nuxt project to
  live in, so #3 now depends on the site shell (#5) instead of the
  reverse. The footer's content comes from a shared content component
  rather than a site-profile record.
- **Issues #3, #5, #7, #8, #9, #10, #11, #12, #13, #15 and #22** have
  been updated to drop records, the site profile, `featured` flags and
  sorting by `order`.
- **The Writing/Blog backlog item (#23)** needs an RSS feed, which is
  generated from a list of posts. If it is picked up, it may need its own
  decision about how posts are listed.
