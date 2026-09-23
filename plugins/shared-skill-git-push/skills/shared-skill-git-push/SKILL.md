---
name: shared-skill-git-push
description: Commit selected changes and push the branch safely.
---

# Git push

Trigger phrase: "git push"

## Purpose

Help the assistant choose the right files, create a commit message from the changes, verify the branch, and push safely.

## Assistant workflow

1. Inspect `git status --short --branch` and `git diff` before doing anything.
2. Ask the user whether to push all changes or only specific files if that is not already clear.
3. If the commit message is not obvious, choose a concise commit message based on the changes.
4. Confirm the current branch name.
5. If the branch is acceptable, stage the intended files together with `git add`.
6. Create the commit with a clear message.
7. Push the branch to the configured remote.
8. If the branch is not acceptable, ask which branch to push to before pushing.

## Manual bash workflow

```bash
git status --short --branch
```
Shows the current branch and what files are modified, added, or untracked.

```bash
git diff
```
Shows the exact content changes so you can decide what should be included.

```bash
git add <files>
```
Stages the files you want in the commit.

```bash
git commit -m "<commit message>"
```
Creates the commit using a message that describes the change.

```bash
git push origin <branch-name>
```
Pushes the committed changes to the selected branch on the remote.

## Notes / approval

Use this skill when the user wants a git push workflow with file selection and branch confirmation.
If the branch name looks wrong or risky, stop and ask before pushing.
