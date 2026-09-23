# MCP Tools Reference

## Tool List

- `health() -> {status, qdrant_ok, index_stats}`
- `list_docs() -> list[str]`
- `list_ips() -> list[str]`
- `search(query: str, top_k: int = 8, filters: dict = {}) -> list`
- `fetch(chunk_id: str) -> {text, metadata}`
- `fetch_pages(pages: list[int], doc_id: str = "") -> {page:int -> markdown}`

## Search Filters

`search(..., filters={...})` applies exact-match metadata filtering (case-insensitive string equality).

Use these common filter keys from chunk metadata:

- `doc_id`
- `ip_name`
- `kind` (`normal` or `register`)
- `section_path`
- `title`
- `source_pdf`
- `page_start`
- `page_end`

## Device/doc_id Requirement

**Always include `doc_id` filter for queries.** Map device names first, then resolve the newest matching revision with `list_docs()`:

- **Tavor** → latest indexed Tavor/NPCM9mnx spec
- **Arbel** → latest indexed Arbel/NPCM845x spec

Default policy:

- Prefer the latest revision for the requested device family.
- Only use an older revision when the user explicitly asks for it.
- For revision comparisons, run separate searches for each explicit `doc_id`.

If user does not specify device, ask before searching:

```python
# DON'T do this (searches both documents, may be confusing):
search("clock enable", filters={})

# DO this (constrain to one resolved device revision):
search("clock enable", filters={"doc_id": "<latest_tavor_doc_id>"})
```

## Practical Filter Strategy

1. Always start with `doc_id` (mapped from device name).
2. Add `ip_name` if user specifies a module (UART, TIMER, etc.).
3. Add `kind=register` for register-specific questions.
4. If no results with full filters:
   - Drop `kind`, retry.
5. If still weak:
   - Drop `ip_name`, retry with just `doc_id`.
6. Only in edge cases: remove `doc_id` for global cross-device search.

## Multi-Doc Behavior

- `fetch_pages` can return an error when multiple documents exist and `doc_id` is omitted.
- Provide `doc_id` for page fetches whenever more than one document is indexed.

## Transport Endpoints

- Streamable HTTP: `http://127.0.0.1:8765/mcp`
- SSE: `http://127.0.0.1:8765/sse`
