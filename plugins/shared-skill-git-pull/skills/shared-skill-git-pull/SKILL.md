---
name: shared-skill-git-pull
description: Pull from a chosen remote and branch after showing remotes, branches, and a preview of the result.
---

# Git pull

Trigger phrase: "git pull"

## Purpose

Pull changes from a remote branch safely: first show which remotes and branches
are available, then preview exactly what the pull would bring in, and only perform
the pull after the user confirms.

## Assistant workflow

1. Show the available remotes to pull from with `git remote -v`, and note the current branch from `git status --short --branch`.
2. Decide the `<origin>`: if the user named one, use it; otherwise ask which remote to use, defaulting to `origin` when only one exists.
3. Fetch the chosen remote with `git fetch <origin>`, then show the branches available to pull from with `git branch -r`.
4. Decide the `<branch>`: if the user named one, use it; otherwise ask, defaulting to the current branch's upstream when it is set.
5. Show the final result preview before pulling:
   - the commits that would be merged in: `git log --oneline HEAD..<origin>/<branch>`
   - a file-level summary: `git diff --stat HEAD..<origin>/<branch>`
   - whether it fast-forwards or would need a merge commit.
6. Ask the user to confirm. Only after confirmation, run `git pull --ff-only <origin> <branch>`, falling back to a normal pull or rebase only if the user asks.
7. Report the result, including the new `HEAD` commit.

## Manual bash workflow

```bash
git remote -v
```
Lists the remotes you can pull from, with their fetch and push URLs.

```bash
git status --short --branch
```
Shows the current branch and whether the working tree is clean before pulling.

```bash
git fetch <origin>
```
Updates the remote-tracking refs for `<origin>` so the preview uses current data.

```bash
git branch -r
```
Lists the remote branches available to pull from, after fetching.

```bash
git log --oneline HEAD..<origin>/<branch>
```
Shows the commits the pull would add — the preview of the final result.

```bash
git diff --stat HEAD..<origin>/<branch>
```
Shows which files would change and by how much, without modifying anything.

```bash
git pull --ff-only <origin> <branch>
```
Performs the pull once confirmed. `--ff-only` refuses a surprise merge and stops
if the branches have diverged, so you can decide how to integrate.

## Notes / approval

Use this skill when the user wants to pull. Always show the remotes, the branches,
and the commit and diff preview first, and wait for confirmation before pulling.
If the working tree is dirty or the pull cannot fast-forward, stop and ask how to
proceed.
