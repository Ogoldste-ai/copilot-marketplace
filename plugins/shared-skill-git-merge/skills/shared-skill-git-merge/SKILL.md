---
name: shared-skill-git-merge
description: Merge a chosen source branch into the current branch after showing all available branches and a preview.
---

# Git merge

Trigger phrase: "git merge"

## Purpose

Merge a source branch into the current branch safely: always show all the branches
available to merge from first, preview what the merge would bring in, and only
perform the merge after the user confirms.

## Assistant workflow

1. Show the current branch — the merge target — from `git status --short --branch`, and confirm the working tree is clean.
2. Show all available source branches to merge from with `git branch -a` (local and remote-tracking), after `git fetch` so the list is current.
3. Decide the `<src>` branch: if the user named one, use it; otherwise ask which branch to merge from. Never assume.
4. Show the preview before merging:
   - the commits that would be merged in: `git log --oneline HEAD..<src>`
   - a file-level summary: `git diff --stat HEAD..<src>`
   - whether it fast-forwards or would create a merge commit.
5. Ask the user to confirm the merge of `<src>` into the current branch.
6. Only after confirmation, run `git merge --no-ff <src>` so the merge is explicit and reviewable.
7. If there are conflicts, stop and surface them for the user — never auto-resolve. Otherwise report the result, including the new `HEAD` commit.

## Manual bash workflow

```bash
git status --short --branch
```
Shows the current branch (the merge target) and whether the working tree is clean.

```bash
git fetch
```
Updates remote-tracking refs so the branch list and preview are up to date.

```bash
git branch -a
```
Lists all available source branches — local and remote — to merge from.

```bash
git log --oneline HEAD..<src>
```
Shows the commits the merge would add — the preview of what will come in.

```bash
git diff --stat HEAD..<src>
```
Shows which files would change and by how much, without modifying anything.

```bash
git merge --no-ff <src>
```
Merges `<src>` into the current branch once confirmed. `--no-ff` records an explicit
merge commit so the integration is easy to see and revert.

## Notes / approval

Use this skill when the user wants to merge a branch into the current one. Always
show the available branches and the commit and diff preview first, and wait for
confirmation before merging. If the working tree is dirty, stop and ask. On merge
conflicts, stop and surface them rather than resolving automatically.
