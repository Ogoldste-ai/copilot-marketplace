---
name: shared-skill-marketplace-update-all
description: Sync marketplace skills and agents across the marketplace.
---

# Update marketplace skills

Trigger phrase: "update marketplace"

Every marketplace item lives in exactly one place: its plugin package under `plugins/`.
There is no separate top-level `skills/` or `agents/` copy to mirror from.

- a skill lives at `plugins/<name>/skills/<name>/SKILL.md`
- an agent lives at `plugins/<plugin>/agents/<agent>.agent.md`

When asked to update marketplace skills and agents, follow this workflow:

1. Find the source skills in `~/.copilot/skills` and `~/tavor/nuvoton-caliptra-mcu-sw-validation/.github/skills`.
2. Compare each source skill with the matching `~/tavor/nuvoton_copilot_marketplace/plugins/<name>/skills/<name>/SKILL.md`.
3. Compare each source agent with the matching `~/tavor/nuvoton_copilot_marketplace/plugins/<plugin>/agents/<agent>.agent.md`.
4. Update the existing `SKILL.md` and `*.agent.md` files in place so their content matches the source.
5. For a new skill, create `~/tavor/nuvoton_copilot_marketplace/plugins/<name>/` with a `plugin.json`
   (`"skills": ["skills/"]`) and `skills/<name>/SKILL.md`.
6. For a new agent, create or extend a plugin with a `plugin.json` (`"agents": "agents"`) and add
   `agents/<agent>.agent.md`.
7. Register the plugin in `~/tavor/nuvoton_copilot_marketplace/.github/plugin/marketplace.json`.
8. Keep `~/tavor/nuvoton_copilot_marketplace/marketplace/skills_catalog.json` and
   `~/tavor/nuvoton_copilot_marketplace/marketplace/agent-catalog.json` aligned with the file paths,
   triggers, and display names.
9. Review the final diff before finishing.

Manual bash workflow:

```bash
ls ~/tavor/nuvoton_copilot_marketplace/plugins
```
Lists the marketplace plugin packages, which are the source of truth.

```bash
find ~/.copilot/skills ~/tavor/nuvoton-caliptra-mcu-sw-validation/.github/skills -name SKILL.md -print
```
Lists the source skills to compare against.

```bash
find ~/tavor/nuvoton_copilot_marketplace/plugins -name 'SKILL.md' -o -name '*.agent.md' | sort
```
Lists every published skill and agent file in the marketplace.

```bash
sed -n '1,200p' ~/tavor/nuvoton_copilot_marketplace/plugins/<name>/skills/<name>/SKILL.md
```
Shows the current marketplace skill file before editing it.

```bash
git diff -- ~/tavor/nuvoton_copilot_marketplace/plugins ~/tavor/nuvoton_copilot_marketplace/.github/plugin/marketplace.json ~/tavor/nuvoton_copilot_marketplace/marketplace/skills_catalog.json ~/tavor/nuvoton_copilot_marketplace/marketplace/agent-catalog.json
```
Shows the exact plugin and catalog changes before approval.

Notes / approval:
Treat `plugins/<name>/` as the single source of truth for every marketplace item. Edit those files
directly, then keep `marketplace.json` and the two catalogs in sync with them.
