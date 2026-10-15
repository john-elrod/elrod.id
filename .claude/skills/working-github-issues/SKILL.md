---
name: working-github-issues
description: Use when John asks to work, implement, execute, pick up, start, or complete a GitHub issue for elrod.id (e.g. "work issue #7", "do the next v1 issue"), or to open a pull request for an issue.
---

# Working GitHub Issues

## Overview

An issue is done when there is a pull request to `main` that delivers
exactly what the issue asks for, with evidence for every acceptance
criterion. **John reviews and merges. Claude never merges, never pushes
to `main`, and never closes issues by hand.**

## Steps

1. **Read the issue in full:**
   ```bash
   gh issue view <n> --repo john-elrod/elrod.id --comments
   ```
   - If the issue is closed, stop and tell John.
   - If the user asked for "the next issue", list the open `v1` issues
     whose dependencies are all closed, and confirm the choice with John.
2. **Check dependencies.** For each `#d` on the `Depends on:` line, run
   `gh issue view <d> --json state,title`. If any dependency is still
   open, stop. Report what is blocking and do not start work.
3. **Check for decisions John needs to make.** If the issue needs a
   choice the spec and `CLAUDE.md` don't settle (stack, hosting, visual
   direction, scope), present the options with a recommendation and wait.
   For decision-record issues, the deliverable is the record itself in
   `docs/decisions/`. It goes up as a PR for John to approve.
4. **Prepare a clean branch:**
   ```bash
   git status --porcelain        # must be empty; if not, stop and ask
   git switch main && git pull --ff-only
   git switch -c <type>/<n>-<short-slug>
   ```
5. **Implement.** Follow `CLAUDE.md` and the spec. Use
   superpowers:test-driven-development for any code that has behavior.
   Make only the changes the issue asks for. If you find other needed
   work, file it with the `creating-github-issues` skill and mention it
   in the PR. Don't fold it into this PR.
6. **Verify.** **REQUIRED SUB-SKILL:** superpowers:verification-before-completion.
   - Run every check that exists: build, lint, tests, and the CI checks
     once they have been set up.
   - Go through each acceptance criterion and record the evidence: the
     command output, the viewport tested, the keyboard pass.
   - If a criterion can't be met or checked, don't mark it done. Explain
     why in the PR.
7. **Commit** with an imperative subject that references the issue,
   e.g. `Add home page hero (#7)`, followed by the co-author trailer.
8. **Push and open the PR:**
   ```bash
   git push -u origin HEAD
   gh pr create --repo john-elrod/elrod.id --base main \
     --title "<issue title> (#<n>)" --body-file <tmpfile>
   ```
9. **Report** the PR link to John, a one-line summary, and anything
   still open. Then stop. Do not merge.

## PR body template

```markdown
Closes #<n>

## Summary
<What changed and why, 2–4 bullets.>

## Acceptance criteria
- [x] <criterion copied from issue> — <evidence: command/output, viewport, etc.>
- [ ] <criterion not met> — <why, and what is needed>

## Testing
<Commands run and their results; manual checks performed.>

## Notes for review
<Decisions made, trade-offs, follow-up issues filed (#n), screenshots.>
```

## Stop and ask John when

- the working tree is dirty or `main` can't fast-forward
- a dependency is still open
- the issue needs a decision from John or content only he can provide
  (bio, headshot, project details, résumé PDF)
- the acceptance criteria are ambiguous, or they conflict with the spec
- a required check fails and fixing it would go beyond the issue's scope

## Common mistakes

| Mistake | Fix |
|---|---|
| Ticking a criterion because the code "should" satisfy it | Tick it only with evidence written next to it |
| Fixing unrelated things you noticed along the way | File a new issue and link it in the PR |
| Branching from an old `main` | Run `git pull --ff-only` before branching |
| Using `Fixes #n` in a commit on `main` | Never commit to `main`. Put `Closes #n` in the PR body |
| Merging after the checks pass | John merges. Stop after opening the PR |
