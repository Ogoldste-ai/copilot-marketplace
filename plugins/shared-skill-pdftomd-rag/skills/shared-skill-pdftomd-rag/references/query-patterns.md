# Query Patterns

## Device/Document Disambiguation

Before running any search, identify which device the user is asking about.

**Tavor indicators:**
- Explicit mention: "Tavor", "NPCM9mnx", "fifth-generation BMC"
- Context clues: "newer generation", "1.5 GHz A35", "DDR5", "Caliptra 2.1"

**Arbel indicators:**
- Explicit mention: "Arbel", "NPCM845x", "fourth-generation BMC"
- Context clues: "previous generation", "1.0 GHz A35", "DDR4", "Caliptra"

**Action if ambiguous:**
```
User: "What's the clock enable sequence?"
→ You: "Are you asking about Tavor (NPCM9mnx) or Arbel (NPCM845x)?"
```

Once clarified, resolve the latest matching revision with `list_docs()` and apply that `doc_id` in all subsequent searches unless the user requested an older revision:

```
Filters: {"doc_id": "<latest_tavor_doc_id>"}  # For Tavor by default
  or  {"doc_id": "<latest_arbel_doc_id>"}  # For Arbel by default
```

If the user explicitly asks for an older revision, use the requested revision instead of the latest one.

## Register and Offset Questions

Use when user asks for register location, bit range, access, reset value, or address.

- Primary query pattern:
- `<REGISTER_NAME> offset <HEX_ADDRESS>`
- Example: `TIMER_CTRL offset 0x0100`

- Required filters (always include):
- `doc_id` (resolved from device family, latest by default)
- `ip_name` (if known)
- `kind=register`

- Example with full filters:
```
search(
  "TIMER_CTRL offset 0x0100",
  filters={"doc_id": "<resolved_doc_id>", "kind": "register"}
)
```

## Reset and Init Sequence Questions

Use when user asks for order of operations or programming steps.

- Query pattern:
- `reset sequence and clock enable for <IP>`
- Example: `reset and clock enable sequence for UART`

- Required filters (always include):
- `doc_id` (resolved from device family, latest by default)
- `ip_name` if known

- Example:
```
search(
  "reset and clock enable sequence for UART",
  filters={"doc_id": "<resolved_doc_id>", "ip_name": "UART"}
)
```

## Section Lookup Questions

Use when user names chapter/section, feature, or block description.

- Query pattern:
- `<section phrase> <feature phrase>`
- Example: `virtual UART configuration registers`

- Required filters (always include):
- `doc_id` (resolved from device family, latest by default)

- Example:
```
search(
  "virtual UART configuration registers",
  filters={"doc_id": "<resolved_doc_id>"}
)
```

## Cross-Device Comparison

Use when user explicitly asks to compare Tavor vs Arbel or between revisions.

1. Run search separately for each device:
   ```
   results_tavor = search(query, filters={"doc_id": "<tavor_doc_id>"})
   results_arbel = search(query, filters={"doc_id": "<arbel_doc_id>"})
   ```
2. Fetch full chunk evidence from top candidates of each.
3. Compare only claims backed by evidence from both devices.
4. Call out missing evidence explicitly (e.g., "Feature X only in Arbel").
5. Cite both `doc_id`s in comparison results.

For cross-revision comparison within the same device family, follow the same pattern with two explicit revision `doc_id`s.

## Query Rewrite Heuristics

If retrieval quality is low, rewrite in this order:

1. Add exact register token and hex token.
2. Replace verbose question with keyword phrase.
3. Add likely module name (`UART`, `TIMER`, `I2C`, etc.).
4. Remove stop words and punctuation noise.

## Citation Expectations

For each key claim, include:

- `doc_id`
- `chunk_id`
- `section_path`
- `page_start-page_end`
