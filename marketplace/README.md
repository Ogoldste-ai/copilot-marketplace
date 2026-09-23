# Marketplace overview

This folder defines the shared marketplace contract for skills and agents in this repository.

## Files

- `skills_catalog.json` - machine-readable registry of marketplace items
- `agent-catalog.json` - machine-readable registry of marketplace agents
- `forms/skill-request.yaml` - submission template for new skills
- `forms/agent-request.yaml` - submission template for new agents
- `templates/plugin-manifest.yaml` - starter manifest for new skills
- `templates/agent-manifest.yaml` - starter manifest for new agents
- `schema/plugin-manifest.schema.json` - validation rules for manifests
- `policies/publishing.md` - approval and safety rules
- `process/submit.md` - intake workflow
- `process/review.md` - approval workflow
- `process/publish.md` - authoring and release workflow
- `process/lifecycle.md` - lifecycle state definitions

## Design

The marketplace treats each item as a product entry with:

- a stable id
- a display name
- a trigger phrase
- a source file path
- a lifecycle state
- an owner

The catalog is the source of truth. Items remain plain markdown files, but the catalog makes them discoverable and governable.

Agents are tracked the same way, but through `agent-catalog.json`, and their source files live in
`plugins/<plugin>/agents/`.
