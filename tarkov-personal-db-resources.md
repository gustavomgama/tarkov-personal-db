# Tarkov Personal Database — Resource Document

> **Source priority (updated 2026-08-21):** the **Fandom EFT wiki is the absolute source of truth**
> for everything it exposes (names, descriptions, item infoboxes incl. trader/unlock info + node ids,
> quest infoboxes incl. previous/given-by). json.tarkov.dev is **secondary**, used only where the wiki
> has no machine-readable data (objective counts, barter recipes, hideout costs/levels, min levels).
> See `HANDOFF.md` for implementation details.

Scope: local, single-user reference database. Items, tasks, traders, trader items, task items, hideout, hideout items, hideout requirements. No flea market, no price data, no analytics, no exposed API.

## 1. Data Source

### Preferred: tarkov.dev JSON API (simple GET)
tarkov.dev recommends the **JSON API** going forward over GraphQL. Same underlying data, plain HTTP GET + JSON — easiest fit for a Rails sync rake task (`Faraday` / `HTTParty`, no GraphQL client).

- Base host: `https://json.tarkov.dev`
- Endpoint catalog: https://json.tarkov.dev/endpoints
- Docs page: https://tarkov.dev/api/
- Free, keyless, open source (the-hideout org)

#### Endpoints (from https://json.tarkov.dev/endpoints — fetched 2026-08-12)

```json
{
  "data": {
    "endpoints": [
      {
        "name": "barters",
        "path": "/{{gameMode}}/barters",
        "description": "trader barter offers",
        "translations": false
      },
      {
        "name": "crafts",
        "path": "/{{gameMode}}/crafts",
        "description": "hideout crafts",
        "translations": false
      },
      {
        "name": "hideout",
        "path": "/{{gameMode}}/hideout",
        "description": "hideout stations",
        "translations": true
      },
      {
        "name": "items",
        "path": "/{{gameMode}}/items",
        "description": "items, categories, flea market, armor materials, player levels, mastering, skills",
        "translations": true
      },
      {
        "name": "maps",
        "path": "/{{gameMode}}/maps",
        "description": "maps, goon reports, mobs (bosses), loot containers, stationary weapons",
        "translations": true
      },
      {
        "name": "price history",
        "path": "/{{gameMode}}/prices/{{itemId}}",
        "description": "all flea market price history for an item",
        "translations": false
      },
      {
        "name": "status",
        "path": "/status",
        "description": "EFT server status",
        "translations": false
      },
      {
        "name": "tasks",
        "path": "/{{gameMode}}/tasks",
        "description": "tasks, quest items, achievements, prestige",
        "translations": true
      },
      {
        "name": "traders",
        "path": "/{{gameMode}}/traders",
        "description": "traders",
        "translations": true
      }
    ],
    "gameModes": ["regular", "pve", "pvp-season"],
    "languages": [
      "cs", "de", "en", "es", "fr", "hu", "id", "it", "ja", "ko",
      "pl", "pt", "ro", "ru", "sk", "th", "tr", "vn", "zh"
    ]
  }
}
```

**In-scope endpoints for this project** (skip maps, status, price history):

| Need | Path example |
|------|----------------|
| Items | `GET https://json.tarkov.dev/regular/items` |
| Tasks | `GET https://json.tarkov.dev/regular/tasks` |
| Traders | `GET https://json.tarkov.dev/regular/traders` |
| Barters (trader ↔ item) | `GET https://json.tarkov.dev/regular/barters` |
| Hideout stations | `GET https://json.tarkov.dev/regular/hideout` |
| Crafts (optional) | `GET https://json.tarkov.dev/regular/crafts` |

Use `gameMode` = `regular` or `pve` depending on which edition you play. Append `?lang=en` (or another language code) on endpoints marked `"translations": true` if you want non-default locale.

### Alternative: tarkov.dev GraphQL API — still maintained
Use only if you need field-level selection / nested filtering the JSON dumps don't give cleanly.

- Endpoint: `https://api.tarkov.dev/graphql`
- Playground/docs: https://tarkov.dev/api/
- API source: https://github.com/the-hideout/tarkov-api
- Query examples: https://github.com/the-hideout/tarkov-api/blob/main/docs/graphql-examples.md
- Full schema: https://github.com/the-hideout/tarkov-api/blob/main/schema-static.mjs

Root query fields relevant to this scope: `items`, `tasks`, `traders`, `hideoutStations`, `crafts`, `barters`.

Naming note — old types were renamed: `Quest` → `Task`, `QuestObjective` → `TaskObjective`, `QuestRequirement` → `TaskRequirement`, `HideoutModule` → `HideoutStation`.

### Optional / supplementary sources
- **Fandom Wiki** (lore/flavor only): `https://escapefromtarkov.fandom.com/api.php` — MediaWiki API; not needed for core item/task/hideout tables
- **TarkovTracker structured data** (static dumps some tools clone): https://github.com/TarkovTracker/tarkovdata — useful as a shape reference, not required if you sync from tarkov.dev
- **SPT Forge API** (Single Player Tarkov mods only — out of scope for live EFT reference): https://forge.sp-tarkov.com/developers

## 2. Entities to Query and Store

Prefer pulling from the JSON paths above; GraphQL field notes below still describe the shape of the data.

### 2.1 Items
JSON: `/{{gameMode}}/items` · GraphQL: `items` / `itemsByName` / `itemsByType`

Relevant fields (no price fields needed): `id`, `name`, `shortName`, `description`, `types`, `width`, `height`, `weight`, `iconLink`, `gridImageLink`, `wikiLink`, `category`, plus type-specific properties via inline fragments (e.g. `... on ItemPropertiesWeapon`, `... on ItemPropertiesAmmo`).

### 2.2 Traders
JSON: `/{{gameMode}}/traders` · GraphQL: `traders`

Fields: `id`, `name`, `description`, `resetTime`, `currency`, `levels { level requiredPlayerLevel requiredReputation }`

### 2.3 Trader Items (what each trader buys/sells)
JSON: traders payload + `/{{gameMode}}/barters` · GraphQL nested under `traders`: `cashOffers { item { id name } minTraderLevel price currency }` and `barters { requiredItems { item count } rewardItems { item count } }`

This is your trader ↔ item join data.

### 2.4 Tasks
JSON: `/{{gameMode}}/tasks` · GraphQL: `tasks`

Fields: `id`, `name`, `trader { name }`, `minPlayerLevel`, `taskRequirements`, `kappaRequired`, `finishRewards`, `objectives { ... }`

### 2.5 Task Items (items required/given by task objectives)
Nested under `tasks.objectives`, using inline fragments on the `TaskObjective` interface:
```graphql
... on TaskObjectiveItem {
  item { id name shortName }
  count
  foundInRaid
}
```
This is your task ↔ item join data.

### 2.6 Hideout
JSON: `/{{gameMode}}/hideout` · GraphQL: `hideoutStations`

Fields: `id`, `name`, `levels { level constructionTime description }`

### 2.7 Hideout Items (construction/upgrade item costs)
Nested under hideout station levels:
```graphql
itemRequirements {
  item { id name }
  count
}
```
Also check `/{{gameMode}}/crafts` (or GraphQL `crafts`) for station production recipes (`station { name } level rewardItems { item count } requiredItems { item count }`) if you want craftable outputs, not just construction costs.

### 2.8 Hideout Requirements (what's needed to unlock a station level)
Nested under hideout station levels:
```graphql
stationLevelRequirements { station { name } level }
traderRequirements { trader { name } level }
skillRequirements { name level }
```

## 3. Local-Only Architecture

No exposed API, no controllers/routes needed for external access. This is reference data that only changes on wipes/game patches — no live polling required.

```
json.tarkov.dev (GET /regular/items, /tasks, …)
        │
        ▼  (one-off or manual re-run: rake tarkov:sync)
Rails app — service object / rake task
        │
        ▼
SQLite (or local Postgres) — upsert into local tables
        │
        ▼
Rails views / console — you browse your own data locally
```

- SQLite is sufficient for a single-user local reference DB — no server process needed
- Sync is a pull-and-upsert job you trigger manually or on a schedule (e.g. `whenever` gem for a local cron entry) — not continuous polling
- No `graphql-ruby` needed — you're consuming JSON (or optionally POSTing GraphQL), not serving an API

## 4. Suggested Local Schema (ActiveRecord)

```
items                        (id, name, short_name, description, category, width, height, weight, icon_link, wiki_link)
tasks                        (id, name, trader_id, min_player_level, kappa_required)
traders                      (id, name, description, reset_time, currency)
trader_items                 (trader_id, item_id, min_trader_level, price, currency, barter)  -- join
task_objectives              (task_id, item_id, count, found_in_raid)                          -- join
hideout_stations             (id, name)
hideout_levels               (id, hideout_station_id, level, construction_time, description)
hideout_item_requirements    (hideout_level_id, item_id, count)                                -- join
hideout_requirements         (hideout_level_id, type[station|trader|skill], target_name, level) -- join
```

## 5. Ruby Tools

- Plain `Faraday` or `HTTParty` — preferred with the JSON API (GET + parse)
- `graphlient` — only if you stick with GraphQL: https://github.com/ashkan18/graphlient
- `sqlite3` gem — local file-based DB, zero setup
- `whenever` gem — optional, if you want the sync job on a local schedule instead of manual runs

## 6. Links — Data Sources and Other Resources

### Data APIs (current)
- **JSON API endpoints catalog**: https://json.tarkov.dev/endpoints
- **JSON API docs**: https://tarkov.dev/api/
- GraphQL API: https://api.tarkov.dev/graphql
- GraphQL playground / language examples: https://tarkov.dev/api/
- tarkov-api source: https://github.com/the-hideout/tarkov-api
- GraphQL examples: https://github.com/the-hideout/tarkov-api/blob/main/docs/graphql-examples.md
- GraphQL schema source: https://github.com/the-hideout/tarkov-api/blob/main/schema-static.mjs
- Fandom Wiki API (optional, lore only): https://escapefromtarkov.fandom.com/api.php
- TarkovTracker open data dumps: https://github.com/TarkovTracker/tarkovdata

### Reference implementations worth reading
- tarkov.dev site source (real query usage for items/tasks/traders/hideout): https://github.com/the-hideout/tarkov-dev
- Tarkov Data Manager (how hideout syncs upstream data): https://github.com/the-hideout/tarkov-data-manager
- TarkovTracker.org — quest/hideout progression tracker, closest shape to this project: https://github.com/tarkovtracker-org
- TarkovHandbook — offline overlay for items/quests/hideout, archived but readable: https://github.com/sammereye/TarkovHandbook
- awesometarkov.com — curated list of community tools: https://github.com/uberswe/awesometarkov.com

### Ruby / Rails
- graphlient: https://github.com/ashkan18/graphlient
- graphql-ruby (only if you later expose an API): https://github.com/rmosolgo/graphql-ruby

### Explicitly out of scope, not included
- db4tarkov.com — no public API found, skip
- tarkov-database.com — sunsetted 2024, dead project: https://github.com/tarkov-database
- SPT Forge API — mod catalogue for Single Player Tarkov, not live EFT game data
- Flea market pricing, historical price charts (`/prices/{{itemId}}`), price prediction/AI analytics, RatScanner-style OCR — all removed, not needed for a static reference DB
