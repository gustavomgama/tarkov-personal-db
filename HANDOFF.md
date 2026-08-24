# Project Handoff — Tarkov Personal DB

## Current State (verified working)

### SYNC REFACTOR (2026-08-24) - json.tarkov.dev primary, wiki = fact-checker only

- **GraphQL is dead upstream** (api.tarkov.dev/graphql 503 since 2026-07-21, issue #474 open);
  json.tarkov.dev REST is the same dataset and stays the transport.
- **Names come from localization files** (`{entity}_{lang}` endpoints): entity payloads carry
  `<tid> Name` placeholders; `Tarkov::Localizations` maps them to real display names
  (items `{tid} Name`/`{tid} ShortName`, tasks `{tid} name`, traders `{tid} Nickname`).
  Result: placeholder items 309 -> 1 (one RFID keycard absent upstream).
- **All Fandom write-paths deleted**: FandomNameSyncer, FandomEnrichmentSyncer,
  ItemBackfillSyncer (+ ItemEnricher/UnlockRows). Fandom::Client remains ONLY for the
  version gate (Template:Gameversion) and the fact checker.
- **Accepted data losses** (wiki no longer writes): 492 wiki-source unlock rows (456 money +
  36 craft), previous/next_task_* chain links (dev payload has requirement edges only,
  221/517 tasks), infobox descriptions (columns already gone pre-refactor).
- **Orchestrator steps**: items, traders, tasks, barters, trader_purge, refresh_names -
  one transaction per game version, SyncState recorded after success (unchanged).
- **Fact checker** (`rake tarkov:factcheck`): read-only wiki verification, report-only,
  writes log/factcheck-<version>.md. Checks: name drift vs canonical titles (preset/
  variant suffixes like "(Black)"/"Default" are not drift), task-gated money routes vs
  infobox trader lines, chain gaps where wiki knows a predecessor dev lacks.
  First live run: 312 findings (52 real name diffs, 3 task, 138 unverified routes, 119 gaps).
- **Parity verified** before cutover: shadow-run matched dev-side exactly (3523 unlocks,
  barter 778, loyalty 35, requirements 241); items 5312 (quest-item rows gone by design).

### SCHEMA REDESIGN (2026-08-21) - acquisition-centric model

- ItemUnlock is THE acquisition table: item + item_name + trader (trader_name/trader_id)
  + loyalty_level + unlock_types JSON ([money]/[barter]/[craft]) + task_id FK.
- Sources merged: wiki infobox trader lines (money), dev barters w/ taskUnlock (barter),
  crafts w/ taskUnlock, task finishRewards offerUnlock (money) / craftUnlock (craft).
- TraderItem deleted; BarterSyncer replaces TraderItemSyncer. No cash prices exist in the
  JSON API (0 currency barters) so Item.price/currency stay null until real data exists -
  never default to RUB (fixes USD/EUR-shown-as-RUB complaint structurally).
- Items slimmed to name/icon/grid/wiki_link + price/currency/craft/barter/require_unlock
  + quest_item flag (replaces deleted types column for quest items).
- Tasks slimmed; previous_task_title -> previous_task_id (+name), next_task_id/name set in
  enrichment pass; Task#rewards via new task_rewards join from finishRewards.items.
- Traders slimmed to tid/name/reset_time (+loyalty levels). FandomNameSyncer derives
  trader normalized keys on the fly from dev payload; ItemBackfillSyncer likewise.

Fresh Rails 8.1 / Ruby 4.0 app, SQLite, local-only reference DB. No frontend yet (explicitly deferred).

**Source-of-truth policy (updated 2026-08-24): json.tarkov.dev feeds all data; the Fandom
EFT wiki is consulted only for the version gate and read-only fact-checking - it never
writes.**

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

### Unlockables (Phase A complete)

- `item_backfill` step (ItemBackfillSyncer): for items without wikiLink, searches the wiki by
  normalized_name, verifies infobox `node` == tid before applying (no false positives), then fully
  enriches via ItemEnricher. Threaded (BACKFILL_THREADS=8 default). Live result: nameless items
  327 -> 206; 5106/5312 items carry real names. Items re-sync resets names - always run fandom
  steps after entity syncs (full tarkov:sync handles order).

- `task_requirements` join synced from payload `taskRequirements` (two-pass; stale-edge cleanup).
- `trader_loyalty_levels` synced from traders payload `levels[]`.
- `item_unlocks` parsed from wiki infobox `trader` param in FandomEnrichmentSyncer
  (trader title, LL level, unlocking task title). WikitextParser keeps `<br/>` as "; " separators.
- `Tarkov::UnlockPathResolver` — item → unlock rows → chain walk → entry quests + max required level.
  **Chain sources merged:** tarkov.dev edges first, wiki `previous_task_title` fallback per node
  (wiki is truth where tarkov.dev has gaps — e.g. The Cleaner has empty taskRequirements upstream).
- `rake 'tarkov:unlock[7.62x51mm M80]'` prints the full path. Verified live:
  M80 → Peacekeeper LL4 / Ref LL3 ← The Cleaner ← The Guide ← Wet Job 6..1 (entry L8).
- Known quirk: unlock text sometimes lists multiple traders ("Ref LL3; Peacekeeper LL4") — one row each.

### Quest items & task flags (Phase B partial)

- findQuestItem/plantQuestItem objectives: quest items stored as Item rows with
  types ["questItem"], joined through normal task_objectives (103 live).
- tasks.lightkeeper_required + tasks.faction_name synced.
- Backfill excludes quest items (no wiki infobox to match); they stay nameless by design.

### Crafts & cross-checks (backlog cleared)

- `hideout_crafts` + `craft_items` (kind required/reward) synced from /regular/crafts
  (`HideoutCraftSyncer`; stale-craft cleanup).
- `trader_items.unlock_task_id` populated from barter `taskUnlock`.
- `rake tarkov:crosscheck` compares wiki unlock claims vs dev taskUnlock per item:
  live result 5 checked, 2 agree, 3 disagree (same quest-line variants / unsynced-task
  placeholders), 111 wiki-only claims.

### Query & consistency (Phase C complete)

- `Tarkov::TaskChainView` — requires (up, incl. wiki fallback) + leads_to (down) walks.
- `Tarkov::ItemUnlockLookup` — unlock paths + trader offers in one call.
- `rake tarkov:sanity` — counts + warnings: nameless items, unresolved unlock-task titles,
  raw-tid hideout targets, tasks w/o trader.
- `rake 'tarkov:chain[Quest Name]'` — prints chain both directions.
- `Syncer#call` wrapped in one transaction per game version (all-or-nothing; SyncState recorded
  only after success).
- Unlock-row parsing handles wiki formats: trailing clause ("after completing his task X"),
  leading segment ("TaskName; Trader LLn: variant"), "???" unknowns kept as nil;
  `Task.find_by_wiki_title` strips trailing dots and tries "/"-separated alternative titles.
  Sanity now reports only genuine "???" unknowns (111 rows).

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

### FRONTEND DATA PASS (2026-08-24)

- items.categories (JSON types array) + items.image_link (image8xLink hi-res;
  icon_link now 512px) - migration + ItemSyncer writes.
- CraftSyncer: crafts -> craft-type dev unlock rows; craft-only items get routes.
- TraderPurge KEEP += "BTR Driver", "Lightkeeper" (their gated items, e.g. Aklys
  Velociraptor via Protect the Sky, were losing routes).
- ItemPurge: drops items with no price/barter/craft/task-gate (~2000 removed,
  5312 -> ~3270).
- Items index: currency checkboxes (multi), category checkboxes (buyable/ammo/
  gun/helmet/armor/rig/backpack/headset), sortable columns (name/price; tasks:
  name/level/gates). Armored-rig vs rig not distinguishable upstream; no armored-mask
  type exists in the API.

### Gotchas

0. **Production mode needs a prepared DB**: `RAILS_ENV=production bin/rails db:prepare` then
   `FORCE=1 bin/rails tarkov:sync` - otherwise every page 500s ("Could not find table").
   Local prod run verified working after this (routes stay localhost-constrained).

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

### Local DB cleanup round (post-redesign)

- BarterSyncer: writes trader_name, identity includes loyalty_level (multi-level offers kept),
  reconciles stale barter-type rows; upsert refreshes trader fields on re-sync.
- DenormalizedNamesRefresh runs as final sync step - item_unlocks.item_name always mirrors
  Item.name (fixes 810 stale copies).
- Dead columns removed: tasks.previous_task_title, items.category.
- Backfill now also searches quest items.
- Remaining placeholders are source-absent: 311 items (208 regular w/o wiki page, 103 quest
  items w/o node ids), 6 tasks (event quests w/o wiki pages), 5 event traders (no pages -
  taran/radio-station/mr-kerman/voevoda/survivor). Do not fuzzy-name these.

### Trader prices (2026-08-23)

- "No prices" scope = flea market only. Trader BUY prices wanted and now synced from the
  items payload `buyFromTrader` (price + real currency RUB/USD/EUR; cheapest offer by priceRUB).
- Live: 2598 items priced (1820 RUB / 723 USD / 55 EUR). M80 = $7 USD via Peacekeeper.
- BarterSyncer also materializes cash offers as money-type ItemUnlock rows keyed on
  [item, trader, task, loyalty] - multiple loyalty tiers coexist.

### Frontend v1 (2026-08-23)

- Stack: ERB + Hotwire (turbo-rails/stimulus-rails via importmap) + vendored Bootstrap 5.3
  dark theme (app/assets/{stylesheets,javascripts}; Propshaft has no Sass build).
- Routes are localhost-constrained (127.0.0.1/::1) - keeps local-only promise.
- ItemsController: index w/ search + currency/barter/craft/task-gated filters (SQLite: use
  LOWER(name) LIKE, not ILIKE), show = acquisition routes via ItemUnlockLookup +
  UnlockPathResolver + "needed for tasks" panel.
- Pending views: Tasks, Traders, Hideout (navbar placeholders).

### TASKS BRANCH (2026-08-23) - unlock-navigator focus

Product pivot: system = item-unlock requirement navigator ONLY. Deleted: hideout tables/syncers,
task_objectives, task_rewards, quest_item flag+rows, items.category/grid_image_link.
TaskSyncer slimmed to name/trader/levels/wiki + taskRequirements + finishRewards.offerUnlock.
Frontend: item show = route cards w/ vertical timeline (chain steps, wiki links, loyalty costs
from trader_loyalty_levels, entry quest + total level); Tasks index/show (prev-next nav,
"Unlocks" panel); Traders index/show (loyalty ladder + gated + sold lists). Navbar enabled.
Progress checkboxes deliberately NOT implemented yet.

### Frontend polish + coverage (2026-08-24)

- Pagination: 10/page default, selector up to 200, shared partial (items/tasks).
- Search: token-based AND matching via ApplicationRecord.token_search (order-independent words).
- Coverage: SimpleCov wired, eager_load=true in test env so controllers/helpers count;
  **100.00% line coverage** (86 tests). parallelize(workers:1) required - forked workers
  clobber the merged resultset otherwise.
- False tagline removed; trader wiki links underscore-encoded; compact route chips
  (Buy · X / Barter · Y / Craft + LL cost); text-bg-accent badge CSS defined.

### Requirements-visibility fixes (2026-08-24)

- ROOT CAUSE of missing purchase requirements: FandomEnrichmentSyncer's stale-cleanup
  destroyed dev-created cash-offer rows for items whose wiki page has no trader line.
  Fix: item_unlocks.source column (wiki|dev); each writer only manages its own rows.
- Money-row identity now includes loyalty_level - multiple tiers per trader coexist.
- BarterSyncer cash offers refactored to per-offer sync_money_offer w/ per-offer rescue
  (one bad offer no longer aborts the remaining ~5000-item loop).
- Traders store image_url; condition chips render trader avatars + readable text.
- Item page shows recursive task TREE (branches supported) instead of linear list.
- Verified live: SRO -> PK LL3 $277; Leupold -> PK LL2 $208; M80 full route set.
