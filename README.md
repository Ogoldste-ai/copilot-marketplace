# Copilot Marketplace

This repository is now structured as a Copilot CLI plugin marketplace.

## Copilot-facing layout

- `.github/plugin/marketplace.json` - marketplace registry used by Copilot CLI
- `plugins/` - plugin packages exposed through the marketplace

## Internal catalog

- `marketplace/` - local governance, manifest, and publishing workflow

## Source of truth

Each item lives in exactly one place: its plugin package under `plugins/`.

- a skill lives at `plugins/<name>/skills/<name>/SKILL.md`
- an agent lives at `plugins/<plugin>/agents/<agent>.agent.md`

Edit those files directly. There is no separate top-level copy to mirror from.

## Add this marketplace in Copilot CLI

```bash
copilot plugin marketplace add nuvoton-IS00/nuvoton_copilot_marketplace
```

## Workflow

1. Create or update the item inside its plugin package under `plugins/<name>/`.
2. Make sure `plugins/<name>/plugin.json` points at the right component folder
   (`"skills": ["skills/"]` or `"agents": "agents"`).
3. Register the plugin in `.github/plugin/marketplace.json`.
4. Keep the internal registries in `marketplace/skills_catalog.json` and `marketplace/agent-catalog.json` in sync.
