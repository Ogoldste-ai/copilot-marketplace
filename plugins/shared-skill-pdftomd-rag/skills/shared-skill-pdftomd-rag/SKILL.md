---
name: shared-skill-pdftomd-rag
description: Query hardware specification documents indexed in pdftomd RAG through MCP tools. Use when users ask for register offsets, bit fields, reset or init sequences, IP configuration details, section lookups, or page-cited answers from indexed PDFs. Prefer filtered search by doc_id and ip_name when useful, then verify with fetch and fetch_pages before final answers.
---

# pdftomd RAG Skill

## Device Mapping

Map user device names to document families before searching, then resolve to a `doc_id` with `list_docs()`:

- **Tavor** → latest indexed Tavor/NPCM9mnx specification by default
- **Arbel** → latest indexed Arbel/NPCM845x specification by default

Rules:

- Always prefer the **latest revision** of the requested device unless the user explicitly asks for an older revision or a revision-to-revision comparison.
- Do not hardcode the active document list; discover it with `list_docs()`.
- If multiple revisions exist for the same device family, resolve to the newest matching `doc_id` by default.

## Clarification Workflow

If user question does not specify a device:

1. Check context from conversation history.
2. If still ambiguous, **ask**: *"Are you asking about **Tavor** (NPCM9mnx) or **Arbel** (NPCM845x)?"*
3. Once device is confirmed, use `list_docs()` to resolve the latest matching `doc_id`.
4. Only ask about revision when the user explicitly requests an older revision, names a specific revision, or asks for a comparison between revisions.

## Core Workflow

1. Call `health` first.
2. **Clarify device** if needed (Tavor or Arbel?).
3. Call `list_docs()` when resolving device aliases or checking which revision is latest.
4. Map device name to the latest matching `doc_id` using Device Mapping above.
5. Run `search(query, top_k, filters={"doc_id": "...", ...})` with `doc_id` filter always set.
6. Verify evidence with `fetch(chunk_id)` and `fetch_pages(...)` before final claims.
7. Return claims with citations: `doc_id`, `section_path`, `page_start-page_end`, `chunk_id`.

## When To Load References

- Read `references/mcp-tools.md` for exact tool contracts, metadata fields, and filter behavior.
- Read `references/query-patterns.md` when search quality is weak or question type is ambiguous.
- Read `references/troubleshooting.md` when tools fail or return empty results.
- Read `references/validation-checklist.md` before finalizing high-stakes answers.

## Output Rules

- Do not invent register values, offsets, or reset sequences.
- If evidence is partial or conflicting, state uncertainty clearly.
- Use the latest revision by default when more than one spec exists for the same device family.
- If the user needs an older revision or a cross-revision comparison, constrain by explicit `doc_id` and say so.
