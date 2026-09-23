# Publish workflow

## Author

1. Create or update the item file inside its plugin package: `plugins/<name>/skills/<name>/SKILL.md`
   for skills, or `plugins/<plugin>/agents/<agent>.agent.md` for agents.
2. Fill out a manifest entry using `marketplace/templates/plugin-manifest.yaml` for skills or `marketplace/templates/agent-manifest.yaml` for agents.
3. Check the trigger phrase against the existing catalog.

## Review

1. Validate the manifest shape against `marketplace/schema/plugin-manifest.schema.json`.
2. Confirm the wording is clear and task-focused.
3. Confirm the permissions are narrow enough for the intended use.
4. Move the item from `draft` to `review`.

## Publish

1. Merge the reviewed item into `marketplace/skills_catalog.json` for skills or `marketplace/agent-catalog.json` for agents.
2. Set the item status to `published`.
3. Keep the source file path stable so users can find the item again.

## Deprecate

1. Mark the item as `deprecated`.
2. Leave the source file in place.
3. Add a replacement entry if a new item supersedes it.
