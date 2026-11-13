---
name: fix-issue
description: Fix a GitHub issue end to end. Fetch it, find the root cause, choose a fix, prove it with a test, and report. Use when asked to fix an issue by number ("fix #7", "/fix-issue 7") or to pick the next bug from GitHub.
argument-hint: "<issue number> | next"
---

# Fix a GitHub issue

Repo: `sdvanhoorne/PokemonFarNorth`. GitHub CLI: use `gh` if it's on PATH, otherwise `~/.local/bin/gh`.

## 1. Fetch

- With a number: `gh issue view <N> --comments`
- With `next` or no argument: `gh issue list --label bug --state open --json number,title,labels`. Prefer issues that block others or crash the game, then smallest scope first. Tell the user which one you picked and why before starting.
- Check `git status` and the current branch. If there are unrelated uncommitted changes, tell the user; don't mix them into this fix.

## 2. Understand

- Issue links point at an older commit; **re-read the code at HEAD**, since lines may have moved or the bug may already be fixed. If it's already fixed, say so and stop.
- Find the root cause, not just the line in the issue. Grep for other call sites with the same pattern.
- For battle code, follow `.claude/agents/battle-mechanics.md` and check `docs/battle-engine-v2.md` so the fix moves in the direction of the planned design (but don't start the redesign inside a bug fix).

## 3. Decide the fix

- Prefer the **smallest change that fixes the root cause**, within the issue's scope. Note related problems you find; don't fix them silently.
- **Ask the user** (AskUserQuestion) before choosing when the fix involves a gameplay/rules decision (e.g. Gen 3 vs later mechanics), changes save data or data-file schemas, or has two reasonable approaches with real trade-offs. Otherwise just decide and say what you chose.

## 4. Test first, then fix

Follow the `godot-test` skill:
1. Write a test in `tests/test_<area>.gd` that reproduces the bug (reference the issue: `# Issue #N`).
2. Run it and confirm it **fails** for the right reason.
3. Make the fix.
4. Run the full test suite, scan for `SCRIPT ERROR`, and smoke-launch the game.

If the bug can't be reproduced in a headless test (pure UI/flow), explain why and list the exact steps the user should play-test.

## 5. Review

For non-trivial diffs, have the `gdscript-reviewer` agent review the changed files (give it the diff, not your reasoning). Address real findings.

## 6. Report

Tell the user:
- root cause (one or two sentences)
- what changed, with file links
- test results (actual output counts), what was smoke-tested, and what still needs a manual play-test
- any related problems found but not fixed

**Don't commit, push, comment on, or close the issue unless asked.** When asked to commit, use a message ending in `Fixes #N` so merging closes the issue; when asked for a PR, branch as `fix/<N>-<short-slug>` and put `Fixes #N` in the PR body.
