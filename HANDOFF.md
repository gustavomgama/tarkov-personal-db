# Project Handoff — Tarkov Personal DB

## Current State (verified working)

Fresh Rails 8.1 / Ruby 4.0 app, SQLite, local-only reference DB. No frontend yet (explicitly deferred).

**Source-of-truth policy: the Fandom EFT wiki is authoritative for everything it exposes.**
json.tarkov.dev is secondary/structural only where the wiki has no machine-readable data
(objective counts, barter recipes, hideout costs/levels, min player levels).

### Wiki enrichment (FandomEnrichmentSyncer, runs after FandomNameSyncer)

- `Tarkov::Fandom::WikitextParser` — parses first Infobox template params (brace/link-depth aware,
  pipes inside [[a|b]] handled) + lead paragraph as description (resolves {{PAGENAME}}, strips markup).
- `Tarkov::Fandom::Client#raw_wikitext(titles)` — batched full wikitext via
  `prop=revisions&rvslots=main` (50/batch), input-title-keyed, redirects/normalization resolved.
- items (+4986): `description` = wiki lead sentence; `unlock_text` = infobox `trader` param when it
  mentions a task (e.g. M80 → "Peacekeeper LL4, after completing his task The Cleaner"). 263 items
  currently carry unlock text.
- tasks (+510): `description`; `previous_task_title` from infobox `previous` (quest chain link).
- Quest infobox also has `given by`, `leads to`, `reqkappa` — available for future structured parsing.

### Name resolution (FandomNameSyncer, runs LAST in tarkov:sync)

- `app/services/tarkov/fandom/client.rb` — MediaWiki API wrapper (batched 50/query,
  normalization + redirect resolution via maps, category members w/ cmcontinue pagination).
- items (4986/5312) + tasks (511/517): resolve canonical title from `wiki_link` slug
  (batched pages query). Unmatched keep tarkov.dev placeholder names.
- traders (11/16): matched from `Category:Traders` members via `normalized_name`.
  The 5 unmatched are API-only event traders not on the wiki.
- stations (26/26): wiki has NO per-station pages (all redirect to Hideout article) —
  names come from curated map in `config/hideout_station_names.yml`
  (`HideoutStation::DISPLAY_NAMES`); unknown keys fall back to raw normalized name.
- NOTE: base syncers overwrite names with API values each run; fandom step must run after
  (orchestrator order handles this; standalone subtasks like `tarkov:sync:items` restore
  placeholders until `tarkov:sync:fandom_names` is re-run).
- Empty-string wikiLinks (167 items) handled gracefully.

### Version gate (tarkov:sync only triggers on game version change)

- `Tarkov::Fandom::Client#latest_game_version` parses `Template:Gameversion`
  (wikitext `[[Changelog|<version>]]`) on the wiki — one tiny request.
- `SyncState` table stores each synced version + timestamp.
- `rake tarkov:sync` aborts if the live version can't be fetched (FORCE=1 does NOT bypass that);
  skips if unchanged ("already synced"); runs + records when changed.
- Per-entity subtasks (`tarkov:sync:<entity>`) are manual repair tools and are NOT gated.
- Current version as of 2026-08-21: **1.1.0.1.46911**.

### Built & Verified

- **Schema**: 9 tables keyed by remote `tid` + `traders.normalized_name`,
  `hideout_stations.normalized_name`, `tasks.wiki_link` (items already had it),
  `items.types` JSON-serialized text (SQLite has no array cols).
- **Models** with associations/validations.
- **Sync pipeline**: Tarkov::Client (json.tarkov.dev) + Fandom::Client (wiki) +
  per-entity Syncers + FandomNameSyncer + orchestrator (`Tarkov::Syncer`) +
  rake: `tarkov:sync[items|traders|tasks|barters|hideout|fandom_names]`,
  env GAME_MODE=regular|pve, TARKOV_LANG=en.
- **Tests**: 24 runs, 94 assertions, green. Fakes: FakeTarkovClient, FakeFandomClient
  (test/support/). Faraday test adapter used for both clients (path `/api.php` for fandom).
- **Lint**: rubocop clean.
- **Live verified**: M80 → "7.62x51mm M80"; tasks → real quest names; traders/stations named.

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
2. **Upstream placeholder names**: json.tarkov.dev returns `"<tid> Name"` style placeholders for all name
   fields regardless of lang; FandomNameSyncer fixes display names (see above).
3. Barter `offeredItem.item` holds the item tid (not `.id`).
4. Hideout station `name` from API is a localization key (`hideout_area_13_name`), not a placeholder —
   curated YAML map is the only sane source for those.
5. Fandom wiki redirects station-like titles to the "Hideout" article with `tofragment: Modules`.

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
