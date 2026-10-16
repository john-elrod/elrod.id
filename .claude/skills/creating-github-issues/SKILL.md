---
name: creating-github-issues
description: Use when John asks to create, file, open, log, or add a new GitHub issue, bug report, feature request, task, or backlog item for the elrod.id repository — including several issues at once.
---

# Creating GitHub Issues

## Overview

GitHub Issues is the system of record for elrod.id work. Every issue must
be implementable by someone who reads only that issue. That means each
one has a user story, testable acceptance criteria, and explicit
dependencies.

## Steps

1. **Understand the request.** If the scope or intended outcome is
   unclear, ask John one focused question. If the scope is clear, draft
   the issue from the request plus the spec
   (`docs/specs/*-design.md`) and `CLAUDE.md`.
2. **Check for duplicates:**
   `gh issue list --state all --search "<keywords>" --limit 20`.
   If one already exists, show John the link and ask whether to update
   that issue or create a new one.
3. **Find which labels and milestones exist.** Use only those. Never
   create labels or milestones without asking.
   ```bash
   gh label list
   gh api repos/john-elrod/elrod.id/milestones --jq '.[].title'
   ```
   If a label or milestone you'd expect is missing, create the issue
   without it and tell John.
4. **Write the body** to a temporary file outside the repo using the
   template below.
5. **Create the issue:**
   ```bash
   gh issue create --repo john-elrod/elrod.id \
     --title "<title>" --body-file <tmpfile> \
     --label "<a>,<b>" --milestone "<v1|Backlog>"
   ```
6. **Report back** with the issue number, link, labels, milestone and
   dependencies. When creating several related issues, create them in
   dependency order so that `Depends on` can cite real issue numbers.

## Body template

```markdown
## Summary
<One or two sentences: what and why.>

## User story
As a <visitor type | John | maintainer>, I want <capability> so that <benefit>.

## Scope
- <What is included>

**Out of scope:** <what is explicitly excluded, or "None">

## Acceptance criteria
- [ ] <Specific, observable, testable outcome>
- [ ] <...>
- [ ] Meets site-wide requirements (spec §6) where applicable: mobile-first at 360/768/1280 px, WCAG 2.1 AA, dark-theme contrast, works without JavaScript

## Dependencies
Depends on: #<n>, #<n>   <!-- or "None" -->

## Notes
<Links to spec sections, design references, open questions for John.>
```

## Rules for acceptance criteria

- Every criterion must be checkable with a true/false answer by a tester.
  Good: "Nav collapses behind a menu button below 1024 px." Bad: "Nav
  looks good on mobile."
- Include the edge cases: no JavaScript, keyboard only, empty content,
  long text.
- For decision issues (stack, hosting, visual design), the criteria are
  "a decision record exists in `docs/decisions/` with options, trade-offs
  and a recommendation", plus "John has approved it".

## Common mistakes

| Mistake | Fix |
|---|---|
| Body passed inline with `--body` breaks on quotes or newlines in PowerShell/Git Bash | Always use `--body-file` |
| Invented label such as `frontend` | Use only labels from `gh label list` |
| Dependencies written in prose ("after the nav is done") | Use the `Depends on: #n` line. The `working-github-issues` skill reads it |
| Vague title ("Home page stuff") | Title should be a short, specific outcome, e.g. "Home page: `#contact` section" |
