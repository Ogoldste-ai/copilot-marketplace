# Troubleshooting

## Device/doc_id Not Specified

Symptom:
- User asks question without mentioning Tavor or Arbel.
- Unclear which document to search.

Actions:
1. Check conversation history for context clues.
2. If still unclear, ask: *"Are you asking about **Tavor** (NPCM9mnx, fifth-gen) or **Arbel** (NPCM845x, fourth-gen)?"*
3. Once clarified, call `list_docs()` and resolve the latest matching `doc_id` for that device family.
4. Only ask for a specific revision if the user asks for an older spec or a comparison.

## Wrong Document Searched

Symptom:
- Results don't match user's expected device (e.g., user asked about Tavor but got Arbel results).

Actions:
1. Verify user actually meant the device they claimed.
2. Check `doc_id` in the result metadata and confirm it belongs to the intended device family.
3. If multiple revisions exist, confirm whether the answer should use the latest revision or a specific older revision.
4. Re-run search with the correct `doc_id` filter.

## Health Fails

Symptom:
- `health` returns error or `qdrant_ok=false`.

Actions:
1. Verify Qdrant container is running and reachable on configured URL.
2. Verify MCP container started with expected transport endpoint.
3. Recreate MCP container if chunk map and bm25 cache were recently updated.

## Search Returns Empty

Symptom:
- `search` returns no useful results.

Actions:
1. Validate `doc_id` via `list_docs`.
2. Validate `ip_name` via `list_ips`.
3. Remove `kind` filter, then retry.
4. If multiple revisions exist, make sure the latest intended `doc_id` was selected.
5. Rewrite query to include exact register name and hex address.

## fetch_pages Error With Multiple Docs

Symptom:
- Error indicates multiple documents are indexed.

Actions:
1. Provide `doc_id` in `fetch_pages`.
2. If user did not specify document, ask for preferred `doc_id`.

## Stale Results After Reindex

Symptom:
- New document exists on disk but MCP answers from old data.

Actions:
1. Confirm `chunk.py` and `embed_index.py` were run.
2. Recreate MCP container so in-memory maps reload.
3. Re-run `list_docs` to confirm active document set.

## Transport Mismatch

Symptom:
- Client session terminates or 404.

Actions:
1. For streamable-http, use `/mcp`.
2. For SSE, use `/sse`.
3. Match client transport mode to server transport mode.
