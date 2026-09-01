# tarkovmarket — Postman collection

Generated from the Postman **tarkovmarket** collection in the **TARKOV** workspace.

- **Collection UID:** `50057549-efc5639f-836e-44ac-bf3d-53e95055d97a`
- **Created:** 2026-08-28T17:30:14Z · **Last updated:** 2026-08-28T17:46:03Z
- **Base URL (env `tarkovmarket`):** `https://api.tarkov-market.app/api/v1`
- **Auth:** API key in the `x-api-key` header (bind from an env var, never hardcode).

## Endpoints

| Request | Path | Query params | Saved response file |
| --- | --- | --- | --- |
| `/item` | `GET {{base_url}}/item` | `q` (query), `uid`, `bsgId`, `lang` | [`item.json`](item.json) |
| `/items/all` | `GET {{base_url}}/items/all` | `tags`, `sort`, `sort_direction`, `lang` | [`items_all.json`](items_all.json) |
| `/items/all/download` | `GET {{base_url}}/items/all/download` | `lang` | [`items_all_download.json`](items_all_download.json) |

All responses are JSON arrays of item objects. `items_all.json` and
`items_all_download.json` are the full list (4,565 items each, identical payload).

## Response fields

| Field | Meaning |
| --- | --- |
| `uid` | Tarkov Market item id — stable, use it as the key on your side |
| `bsgId` | Item id from the game files |
| `name` / `shortName` | Item name in the requested locale |
| `tags` | Item categories, the same ones the website filters by |
| `price` | Last known flea market price, ₽. 0 means no price for this mode |
| `avg24hPrice` / `avg7daysPrice` | Average flea price over the last 24 hours / 7 days, ₽ |
| `diff24h` / `diff7days` | Change of the last price against those averages, % |
| `basePrice` | Item base (handbook) price, ₽ — what trader buy-back is calculated from |
| `traderName` | Trader who pays the most for the item |
| `traderPrice` / `traderPriceCur` | What that trader pays, in his own currency (₽, $ or €) |
| `traderPriceRub` | The same trader price converted to ₽ at the in-game rate |
| `bannedOnFlea` | Item cannot be sold on the flea market |
| `haveMarketData` | Item is tradable on the flea and its price is fresh — false means do not trust price |
| `isFunctional` | false for items removed from the game or not obtainable |
| `updated` | When the flea price was last seen by the scanner. Empty means never |
| `slots` | Inventory size of the item in grid cells |
| `img` / `imgBig` | Item icon and large image on our cdn |
| `icon` | Legacy alias of img — same url |
| `link` / `wikiLink` | Item page on tarkov-market.com and on the wiki |

## Limits & errors

| Rule | Details |
| --- | --- |
| 300 req/min | Per key, across all endpoints. Ask if your project needs more. |
| 5 req/min | Full item list (`/items/all`, `/items/all/download`) in every mode. Prices are cached for 5 minutes anyway. |
| 401 | Key missing, unknown or disabled. |
| 429 | Rate limit reached — the body says which limit it was. |

## Related client code

- Installed Postman clients: `app/services/tarkovmarket/`
  (`Tarkovmarket::Item` / `ItemsAll` / `ItemsAllDownload`, each
  `.call(base_url:, api_key:, …)`).
- Primary internal client: `app/services/tarkov/market_client.rb`
  (`Tarkov::MarketClient`, offline snapshot fallback via
  `refjsons/tarkovmarketitems.json`).