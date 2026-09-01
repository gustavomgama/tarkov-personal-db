# ADR-0001: Task data model mirrors tasks_index.json

- Status: Accepted
- Date: 2026-09-01

## Context

The v2.0 reference DB rebuild starts with the Task domain. The source of truth is
`offlinedata/tarkovunlockables/tasks_index.json` (519 tasks), a curated snapshot that
cross-links tarkov.dev, tarkov-market, and the EFT wiki. The user directive: treat
`tasks_index.json` as the literal schema for the model.

The document is deeply nested per task:

```json
{
  "id": "...", "full_name": "...", "name": "...", "wiki_link": "...",
  "given_by": "...", "kappa_required": true, "lightkeeper_required": false,
  "leads_to": [{ "task_id": "...", "task_name": "..." }],
  "requirements": [{ "player_level": 0, "trader_level": [], "previous_tasks": [] }],
  "start_rewards":  [{ "loose_items": [...], "offer_unlocks": [...],
                       "barter_unlocks": [...], "craft_unlocks": [...] }],
  "finish_rewards": [ /* same shape */ ]
}
```

Nested arrays hold up to 4 levels (finish_rewards → loose_items → item objects).
52 rows (Ref-given tasks without a game id) have a blank `id`, `name`, and
`wiki_link`; all non-blank `id` values are unique.

## Decision

Model as a **single `tasks` table**: one real column per top-level scalar field,
one `jsonb` column per top-level array.

- Scalar columns: `bsg_id` (from `id`), `name`, `full_name`, `wiki_link`,
  `given_by`, `kappa_required`, `lightkeeper_required`
- JSONB columns (default `[]`, non-null): `leads_to`, `requirements`,
  `start_rewards`, `finish_rewards`

Partial unique indexes on `bsg_id` and `name` (only where non-blank), plus
non-unique indexes on `given_by`, `kappa_required`, `lightkeeper_required`,
`full_name`.

## Consequences

**Positive**
- Faithful to the source document; no data reshaping on import or lossy mapping.
- Single table, no join burden; fast to build a reference/read model.
- Blank-`id`/`name` rows remain representable (accept default `""`).

**Negative / deferred**
- Nested reward/requirement data is not directly queryable in SQL — must be
  traversed in application code. Deferred until a concrete query need exists
  (e.g. "list tasks that reward item X"), at which point an index or view can be
  added without reshaping the table.
- Task-to-task references (`leads_to`, `previous_tasks`) are stored as JSON blobs
  of `task_id`/`task_name`, not FKs. Integrity is not enforced at the DB layer.
