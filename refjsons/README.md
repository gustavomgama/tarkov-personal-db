# refjsons/

Local API snapshots used by `Tarkov::Client` for offline syncs. When
`refjsons/<endpoint>.json` exists it is preferred over the network.

- `items.json`, `tasks.json`, `traders.json`, `barters.json`, `crafts.json`,
  `hideout.json` — raw tarkov.dev responses (`{"data": ...}`)
- `*_en.json` — localized name dictionaries for the same sources
- `tarkovmarketitems.json` — tarkov-market.com item dump (contains your API
  key; never commit it — `.gitignore` excludes all JSONs here)

Refresh any snapshot by re-saving the endpoint response in the same shape.
