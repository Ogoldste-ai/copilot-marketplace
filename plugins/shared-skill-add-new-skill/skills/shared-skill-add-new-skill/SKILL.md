---
name: shared-skill-add-new-skill
description: Draft and normalize a new skill into the repository's standard skill template.
---

# Add new skill

Trigger phrase: "add skill"

When asked to add a new skill, follow this workflow:

1. Ask the user for a plain-language description of what the skill should do.
2. If the user already has a `SKILL.md` draft or other Markdown draft, ask for it and treat it as the starting point.
3. Ask for the trigger phrase if it is not already obvious from the request.
4. Draft or normalize the skill into the standard template before finalizing it.
5. Include both:
   - the workflow for how the assistant should execute the skill
   - the bash commands the user can run manually
6. Explain each bash command in plain language.
7. If the user provided a `.md` file, update it to match this format instead of inventing a new layout.
8. Add the new skill as its own directory under `.github/skills/` with a `SKILL.md` file inside it.
9. Show the directory location and open `SKILL.md` for user approval.

Template structure for the new skill:

- Title
- Purpose
- Trigger phrase
- Assistant workflow
- Manual bash workflow
- Notes / approval section

Use an explicit trigger phrase field in the skill template, for example:

```md
Trigger phrase: "add new skill"
```

Manual bash workflow for creating and reviewing a new skill:

```bash
ls .github/skills
```
Use this to confirm the skills directory exists and to see the current skill files.

```bash
sed -n '1,200p' .github/skills/<new-skill>/SKILL.md
```
Use this to review the generated skill template without editing it.

```bash
git diff -- .github/skills/<new-skill>/SKILL.md
```
Use this to inspect the exact changes before asking the user to approve them.

If the user approves the template, keep the file and continue. If the user requests changes, update the template and show it again.
