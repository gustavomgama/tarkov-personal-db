# tarkov.dev — Postman collection

Generated from the Postman **tarkov.dev** collection in the **TARKOV** workspace.

- **Collection UID:** `50057549-729bce5c-dbec-4bf2-ae27-2be92f09cd03`
- **Created:** 2026-08-28T17:32:38Z · **Last updated:** 2026-08-28T18:00:45Z
- **Base URL (env `tarkovdev`):** `https://json.tarkov.dev/regular`
- **Auth:** none (open JSON API)

## Endpoints

All requests are `GET`. No query parameters. Every response envelope is
`{ "data": …, "translations": [] }`.

| Request | Path | Saved response file |
| --- | --- | --- |
| `/barters` | `GET {{base_url}}/barters` | [`barters.json`](barters.json) |
| `/crafts` | `GET {{base_url}}/crafts` | [`crafts.json`](crafts.json) |
| `/items` | `GET {{base_url}}/items` | [`items.json`](items.json) |
| `/tasks` | `GET {{base_url}}/tasks` | [`tasks.json`](tasks.json) |
| `/traders` | `GET {{base_url}}/traders` | [`traders.json`](traders.json) |

## Response shapes (from the saved Postman examples)

### `GET /barters`

```json
{
  "data": [{
    "id": "string",
    "trader": "string",
    "taskUnlock": "string|null",
    "requiredItems": [{ "item": "string", "count": "number", "attributes": "object" }],
    "restockAmount": "number",
    "buyLimit": "number",
    "minTraderLevel": "number",
    "offeredItem": { "item": "string", "count": "number", "attributes": "object" }
  }],
  "translations": []
}
```

### `GET /crafts`

```json
{
  "data": [{
    "id": "string",
    "requiredItems": [{ "item": "string", "count": "number", "attributes": { "tool": "boolean" } }],
    "requiredQuestItems": [],
    "station": "string",
    "duration": "number",
    "gameEditions": [],
    "level": "number",
    "taskUnlock": "string|null",
    "productItem": { "item": "string", "count": "number", "attributes": "object" }
  }],
  "translations": []
}
```

### `GET /items`

`data` is a hash keyed by item id. Each item has been pruned to the key set
shown in [`itemexample.json`](itemexample.json): identity (`id`, `name`,
`normalizedName`), dimensions/weight (`width`, `height`, `weight`, `stackMaxSize`), listing
(`lastOfferCount`, `types`), links (`wikiLink`, `link`, `iconLink`, `gridImageLink`,
`baseImageLink`, `inspectImageLink`, `image512pxLink`, `image8xLink`),
categories (`categories`, `handbookCategories`), modifiers
(`conflictingItems`, `conflictingSlotIds`, `conflictingCategories`),
item-specific `properties` (gun/armor/container/etc. stats — kept whole,
varies by type), and trade data (`buyFromTrader`: `trader`, `price`,
`priceRUB`, `currency`, `minTraderLevel`, `taskUnlock`, `buyLimit`;
`sellToTrader`: `trader`, `price`, `priceRUB`, `currency`).

Removed as not present in the example: `shortName`, `description`, `updated`,
`hasGrid`, `containsItems`, `discardLimit`, `minLevelForFlea`, pricing
(`basePrice`, `lastLowPrice`, `avg24hPrice`, `low24hPrice`, `high24hPrice`,
`changeLast48h`, `changeLast48hPercent`, `lastScan`), flat stat keys
(`damage`, `armorClass`, `armorDamage`, `velocity`, `ergonomicsModifier`,
`accuracyModifier`, `recoilModifier`, `recoil`, `loudness`, `maxDurability`,
`blocksHeadphones`, `tracer`, `tracerColor`, `ammoType`, `projectileCount`,
`fragmentationChance`, `ricochetChance`, `penetrationPower`), and trade
extras (`currencyItem`, `restockAmount`). Note that unlike `/barters` and
`/tasks`, this file keeps the raw trader ids in `buyFromTrader[].trader` /
`sellToTrader[].trader` to match `itemexample.json`.

### `GET /tasks`

`data` is a hash keyed by task id. Each task carries `id`, `name`, `trader`,
`wikiLink`, `minPlayerLevel`, `taskRequirements`, `traderRequirements`,
`objectives` (typed by kind: item hand-in, kill/extract/exit objectives, etc.),
`startRewards` / `finishRewards` / `failureOutcome` (each with `traderStanding`,
`items`, `offerUnlock`, `skillLevelReward`, `traderUnlock`, `craftUnlock`, …),
`neededKeys`, `kappaRequired`, `lightkeeperRequired`, `normalizedName`,
`taskImageLink`, `map`, `availableDelaySecondsMin/Max`, `restartable`, `experience`.

Note: `name` values are `<tid> Name` placeholders upstream; display names come from
the `items_en` / `tasks_en` / `traders_en` localization endpoints.

### `GET /traders`

`data` is a hash keyed by `normalizedName` (e.g. `peacekeeper`). Each trader
carries the original `id` (e.g. `5935c25fb3acc3127c3d8cd9`), `name`
(`<normalizedName> Nickname` placeholder), `description`, `normalizedName`,
`currency`, `resetTime`, `discount`, `levels` (`id` `<normalizedName>-<n>`,
`level`, `requiredPlayerLevel`, `requiredReputation`, `requiredCommerce`,
`payRate`, `insuranceRate`, `repairCostMultiplier`), `reputationLevels`
(fence), `imageLink`, `buyAllowed` / `buyProhibited` (`category`, `items`).

## Trader id normalization

The API identifies traders by opaque 24-char ids. In most of these files every
trader reference has been rewritten to the trader's `normalizedName` for
readability:

- `/barters` `trader`
- `/tasks` `trader`, `traderStanding[].trader`, `traderRequirements[].trader`,
  and `traderUnlock`

Exception: `/items` `buyFromTrader[].trader` and `sellToTrader[].trader` keep
the raw trader ids to match `itemexample.json`.

Mapping source: `traders.json` keyed by `normalizedName`, with the raw `id`
retained inside each trader object. Inside `traders.json` itself the trader id
is also normalized wherever it appears — `name` / `description` placeholders
(`<normalizedName> Nickname|Description`) and `levels[].id`
(`<normalizedName>-<n>`, e.g. `54cb50c76803fa8b248b4571-1` → `prapor-1`) —
while the raw `id` field and URL strings (`imageLink`) are left untouched.
Note `name` values are `<tid> Name` placeholders upstream; display names come
from the `items_en` / `tasks_en` / `traders_en` localization endpoints.
Item/craft/task references (e.g. `requiredItems[].item`, `productItem.item`,
`objectives[].item`) still use raw item/category ids.

## Errors

Non-2xx responses surface as `TarkovDev::Base::Error` with the endpoint and HTTP
status. Transport failures (`Faraday::Error`) are wrapped with the endpoint name.

## Related client code

- Installed Postman clients: `app/services/tarkov_dev/`
  (`TarkovDev::Barters` / `Crafts` / `Items` / `Tasks` / `Traders`, each
  `.call(base_url:)`).
- Primary internal client: `app/services/tarkov/client.rb` (`Tarkov::Client`).