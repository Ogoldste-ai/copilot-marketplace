# Submission workflow

## What to submit

Submit a skill or agent request when you want to add a new marketplace item or change an existing one.

## Required fields

- id
- title
- requester
- owner
- summary
- trigger phrase
- target path
- expected permissions

## Steps

1. Fill out `marketplace/forms/skill-request.yaml` for skills or `marketplace/forms/agent-request.yaml` for agents.
2. Add or update the source file inside its plugin package: `plugins/<name>/skills/<name>/SKILL.md`
   for skills, or `plugins/<plugin>/agents/<agent>.agent.md` for agents.
3. Add or update the registry entry in `marketplace/skills_catalog.json` or `marketplace/agent-catalog.json`.
4. Move the request to review.

## Outcome

Approved submissions become published catalog entries. Rejected submissions stay in draft with notes for revision.
