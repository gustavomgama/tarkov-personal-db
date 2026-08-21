# Tarkov Personal DB

Local, single-user reference database for Escape from Tarkov: items, tasks (quest chains),
traders, unlocks, hideout. No flea-market prices, no analytics, no exposed API.

**Source hierarchy:** the [Fandom EFT wiki](https://escapefromtarkov.fandom.com) is the
absolute source of truth for everything it exposes — names, descriptions, item infoboxes
(incl. trader unlock conditions), quest chains (`previous` links). The
[tarkov.dev JSON API](https://json.tarkov.dev) is secondary, filling in structural data the
wiki doesn't machine-readably provide: objective counts, barter recipes, hideout costs,
loyalty levels, player-level requirements.

## Requirements

- Ruby 4.0 (`cat .ruby-version`), Rails 8.1
- SQLite (file-based, zero setup)

## Setup

```sh
bundle install
bin/rails db:prepare
```

## Syncing

```sh
bin/rails tarkov:sync            # full sync, gated on game version changes
FORCE=1 bin/rails tarkov:sync    # force re-sync of the current version
```

The sync fetches the current game version from the wiki's `Template:Gameversion`
(see the [Changelog](https://escapefromtarkov.fandom.com/wiki/Changelog)). If it matches the
last synced version, nothing runs. If the wiki can't be reached, the sync refuses to run.
`SyncState` stores every synced version + timestamp.

Environment flags:

| Flag          | Default    | Purpose                          |
| ------------- | ---------- | -------------------------------- |
| `GAME_MODE`   | `regular`  | `regular` or `pve`               |
| `TARKOV_LANG` | `en`       | Locale for translations-enabled endpoints |
| `BACKFILL_THREADS` | `8`   | Concurrency for wiki name backfill |

Per-entity repair tasks (manual, **not** version-gated):

```sh
bin/rails tarkov:sync:items        # also: traders, tasks, barters, hideout
bin/rails tarkov:sync:fandom_names # restore wiki names after entity syncs
bin/rails tarkov:sync:fandom_enrichment  # descriptions, unlock text, quest prev-links
bin/rails tarkov:sync:item_backfill      # name items missing wikiLinks via node-id match
```

Note: entity subtasks reset names to upstream placeholders; always finish with the fandom
steps (a full `tarkov:sync` handles ordering automatically).

## Querying

```sh
bin/rails 'tarkov:unlock[7.62x51mm M80]'   # how to obtain an item: trader, LL, quest chain, entry quest
bin/rails 'tarkov:chain[Wet Job - Part 6]' # quest chain up and down
bin/rails tarkov:sanity                    # record counts + dangling-reference warnings
```

From the console:

```ruby
item = Item.find_by!(name: "7.62x51mm M80")
Tarkov::ItemUnlockLookup.new(item).call   # unlock paths + trader offers
Tarkov::TaskChainView.new(task).call      # requires / leads_to walks
```

## Architecture

```
json.tarkov.dev ──► Tarkov::Client ─┐
                                    ├─► Tarkov::Syncer (1 transaction per game version)
Fandom MediaWiki API ─► Fandom::Client ─┘        │
  (names, descriptions, infoboxes,               ▼
   quest previous-links, search+node-id     SQLite (upsert by tid)
   verification for backfill)                   │
                                                ▼
                              rake/console query tools (no web layer)
```

Services live in `app/services/tarkov`: one syncer per entity plus `FandomNameSyncer`,
`FandomEnrichmentSyncer`, `ItemBackfillSyncer`, and resolvers (`UnlockPathResolver`,
`TaskChainView`, `ItemUnlockLookup`). Wikitext parsing (infobox params, lead descriptions)
lives in `Tarkov::Fandom::WikitextParser`.

Curated exception: hideout station names come from `config/hideout_station_names.yml`
(the wiki redirects all station pages to the Hideout article).

## Development

```sh
bin/rails test   # Minitest
bin/rubocop      # omakase config
```

See `HANDOFF.md` for implementation notes and gotchas, and
`tarkov-personal-db-resources.md` for the original research document.
