---
name: shared-skill-add-new-rule
description: Create or update a repository rule under ~/.copilot/rules/ when the user asks for a new rule.
---

## Title

Adding a new rule

## Purpose

When the user says `add new rule`, review the request, check whether any missing information is needed, and then add the requested rule under `~/.copilot/rules/`.

## Trigger phrase

`add new rule`

## Assistant workflow

1. Review the user's request and identify the exact rule they want.
2. If repo context is needed, read `.github/copilot-instructions.md` instead of searching for `.github/skills/*.instructions.md`.
3. Check whether the request is clear enough to implement.
4. Ask a single clarifying question if anything important is missing.
5. Propose the rule file changes before editing.
6. Create or update the rule file under `~/.copilot/rules/`.
7. Open the changed file for the user to inspect.

## Manual bash workflow

```bash
ls ~/.copilot/rules
```
List the existing rule files.

```bash
sed -n '1,200p' .github/copilot-instructions.md
```
Review the repository instruction file when you need repo-specific context.

```bash
sed -n '1,200p' ~/.copilot/rules/<rule-file>.instructions.md
```
Review a rule file before changing it.

```bash
git diff -- ~/.copilot/rules/<rule-file>.instructions.md
```
Inspect the exact rule changes before approving them.

## Notes / approval

This skill should not finalize any file changes until the user approves the proposed rule content.
