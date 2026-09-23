# Validation Checklist

Use this checklist before sending final answers from RAG.

## Device Scope

- User specified device or it's clear from context (Tavor or Arbel).
- Correct `doc_id` filter was applied:
  - Tavor → latest indexed Tavor/NPCM9mnx spec by default
  - Arbel → latest indexed Arbel/NPCM845x spec by default
- If multiple revisions exist, latest revision was used unless the user explicitly asked for an older revision.
- If user asked for cross-device comparison, results cite both `doc_id`s.

## Evidence Quality

- `health` reports MCP and Qdrant are healthy.
- The answer is based on retrieved chunks, not assumptions.
- At least one `fetch` call was made for each major claim.

## Scope Quality

- **Device scope is clear** and documented in the response (Tavor or Arbel).
- `ip_name` scope is clear for peripheral-specific questions.
- Filters were relaxed progressively if initial search was too narrow.
- All results have matching `doc_id` in metadata.

## Citation Quality

Every key claim includes:

- `doc_id`
- `chunk_id`
- `section_path`
- `page_start-page_end`

## Ambiguity Handling

- Conflicting snippets are called out explicitly.
- Missing evidence is stated clearly instead of inferred.
- Follow-up question is asked only when ambiguity can change correctness.
