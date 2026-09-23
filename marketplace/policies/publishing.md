# Publishing policy

## Required checks

Before a marketplace item enters the published catalog:

1. It must have a manifest entry in `marketplace/skills_catalog.json` for skills or `marketplace/agent-catalog.json` for agents.
2. Its metadata must match the manifest schema.
3. Its trigger phrase must be unique across the catalog.
4. Its instructions must be scoped to a single task or workflow.
5. Any risky capability must be explicitly documented.

## Lifecycle

- `draft` - not visible in the published catalog
- `review` - waiting on human approval
- `published` - available for use
- `deprecated` - kept for compatibility, but not recommended

## Safety rules

- Do not publish items that request broad filesystem or network access without review.
- Do not publish items that silently mutate external systems.
- Prefer small, purpose-built skills or agents over multipurpose bundles.
- Deprecate old entries instead of deleting them when they are already in use.
