# Project Handoff — Tarkov Personal DB

## Current State (verified working)

Fresh Rails 8.1 / Ruby 4.0 app, SQLite, local-only reference DB. No frontend yet (explicitly deferred).

### Built & Verified

- **Schema** (`db/migrate/`): 9 tables keyed by remote `tid` string with unique indexes:
  `items`, `traders`, `tasks`, `trader_items` (trader↔item join), `task_objectives` (task↔item join),
  `hideout_stations`, `hideout_levels`, `hideout_item_requirements`, `hideout_requirements`
  (type: station|trader|skill). Note: `items.types` is JSON-serialized text (SQLite has no array cols).
- **Models** (`app/models/`): full associations + validations.
- **Sync pipeline**:
  - `app/services/tarkov/client.rb` — Faraday GET wrapper for json.tarkov.dev
    (endpoints: items/tasks/traders/barters/hideout; gameMode + lang injectable).
  - `app/services/tarkov/syncers/{item,trader,task,trader_item,hideout}_syncer.rb` — upsert by tid.
  - `app/services/tarkov/syncer.rb` — orchestrator (items → traders → tasks → barters → hideout).
  - `lib/tasks/tarkov.rake` — `rake tarkov:sync[<entity>]`, env: `GAME_MODE=regular|pve`, `TARKOV_LANG=en`.
- **Tests**: `bin/rails test` — 20 runs, 78 assertions, green. Fake client + fixtures in `test/support/`.
- **Lint**: `bin/rubocop` clean.
- **Live sync verified** into dev DB: items 5312, traders 16, tasks 517, barters 789→770 trader_items,
  hideout stations 26.

### API shapes learned (json.tarkov.dev, gameMode=regular)

- items: `{items: {tid => {...}}, itemCategories: {tid => {normalizedName}}}` — categories[] are tids;
  leaf category name resolved via itemCategories map.
- tasks: `{tasks: {tid => {...}}}`; objectives reference items via `items:[tids]` (findItem/giveItem/
  plantItem) or `item:` single tid (buildWeapon); other objective types have no item refs.
- barters: LIST of `{id, trader, minTraderLevel, offeredItem: {item, count}, requiredItems, taskUnlock?}`.
- hideout: `{stationTid => {levels: [{level, constructionTime, itemRequirements, stationLevelRequirements,
  traderRequirements{trader,value}, skillRequirements}]}}`.
- traders: dict keyed by tid; resetTime ISO8601.

### Gotchas

1. **Stale db/schema.rb shadows migrations on empty DBs** (Rails 8.1 silently loads schema instead of
   running migrations). If schema looks wrong after rebuild: delete `db/schema.rb`, then drop/create/migrate.
2. **Upstream placeholder names**: JSON API returns `"<tid> Name"` / `"<tid> Nickname"` for all name fields
   regardless of lang; GraphQL API was down when checked. Re-sync will pick real names once fixed upstream.
3. Barter `offeredItem.item` holds the item tid (not `.id`).

## PENDING PIVOT (user requested, not started)

Refocus project from general reference DB to **unlockable items & how to get them**, e.g.:
7.62x51mm M80 unlocks after quest "The Cleaner" (Peacekeeper), but that quest sits mid-line — the line's
first quest is "Wet Job - Part 1" which requires player level 14. User wants chain/root-level info for
task-gated items.

Planned changes (not implemented):

1. Migration: add `unlock_task_id` FK (tasks) to `trader_items`; populate from barters' `taskUnlock` tid.
2. New join table `task_requirements(task_id, required_task_id)` from tasks payload `taskRequirements`
   (inspect element shape first: `{task, ...}`).
3. Task model: prerequisite associations (`required_tasks, through: :task_requirements`).
4. Syncer updates: TaskSyncer sync requirements too; TraderItemSyncer resolve unlock_task (tasks sync first).
5. Query/service helper: given an item, walk unlock task → prerequisites recursively → report root quest
   of the line + its min_player_level (+ trader levels along path).
6. Keep no-frontend decision until user asks.

Reference data doc: `tarkov-personal-db-resources.md` (repo root).
