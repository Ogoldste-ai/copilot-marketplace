---
name: local-skill-marketplace-update
description: Update a private marketplace plugin from an existing skill.
---

# Private marketplace update

Trigger phrase: "private marketplace update"

When asked to update a private marketplace plugin from a skill, follow this workflow:

1. Ask for the source skill name if it is not already provided.
2. Locate the source skill in `.github/skills/<skill-name>/SKILL.md`.
3. Create the matching plugin directory in `/homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/plugins/<skill-name>/`.
4. Copy the skill content into `/homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/plugins/<skill-name>/skills/<skill-name>/SKILL.md`.
5. Create `/homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/plugins/<skill-name>/plugin.json`.
6. Register the plugin in `/homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/.github/plugin/marketplace.json`.
7. Add or update the internal catalog entry in `/homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/marketplace/skills_catalog.json`.
8. Open the created plugin files for review before finalizing.

Manual bash workflow:

```bash
ls .github/skills
```
Shows available skills so you can confirm the source skill name exists.

```bash
sed -n '1,200p' .github/skills/<skill-name>/SKILL.md
```
Displays the source skill content that will be copied into the plugin.

```bash
cp .github/skills/<skill-name>/SKILL.md /homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/plugins/<skill-name>/skills/<skill-name>/SKILL.md
```
Copies the skill into the marketplace plugin package.

```bash
sed -n '1,200p' /homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace/plugins/<skill-name>/plugin.json
```
Reviews the plugin manifest after it is created.

```bash
git diff -- /homes/systems/ogoldste/tavor/nuvoton_copilot_marketplace
```
Shows the exact marketplace changes before publishing.

Notes / approval:

This skill should preserve the source skill’s content while fitting it into the marketplace plugin layout.
