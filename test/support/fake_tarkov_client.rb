class FakeTarkovClient
  ENDPOINTS = %w[items tasks traders barters hideout crafts].freeze

  attr_reader :requested

  def initialize(items: { "items" => {}, "itemCategories" => {} },
                 tasks: { "tasks" => {} },
                 traders: {},
                 barters: [],
                 hideout: {},
                 crafts: [],
                 localizations: {})
    @payloads = {
      "items" => items, "tasks" => tasks, "traders" => traders,
      "barters" => barters, "hideout" => hideout, "crafts" => crafts
    }
    @localizations = localizations
    @requested = []
  end

  # Not tracked in +requested+: it is metadata, not an entity payload.
  def localizations
    Tarkov::Localizations.new(**@localizations)
  end

  ENDPOINTS.each do |endpoint|
    define_method(endpoint) do
      requested << endpoint
      @payloads.fetch(endpoint)
    end
  end
end

module TarkovTestFixtures
  def item_payload
    {
      "items" => {
        "item-1" => {
          "id" => "item-1",
          "normalizedName" => "colt-m4a1",
          "name" => "Colt M4A1",
          "buyFromTrader" => [
            { "trader" => "trader-1", "price" => 6500, "priceRUB" => 6500, "currency" => "RUB", "minTraderLevel" => 2 },
            { "trader" => "trader-1", "price" => 70, "priceRUB" => 6300, "currency" => "USD", "minTraderLevel" => 3 }
          ],
          "shortName" => "M4A1",
          "description" => "Assault rifle",
          "types" => [ "gun" ],
          "properties" => { "caliber" => "Caliber556x45NATO", "allowedAmmo" => [ "item-2" ] },
          "categories" => [ "cat-1", "cat-parent" ],
          "weight" => 3.1,
          "width" => 4,
          "height" => 2,
          "iconLink" => "https://assets.tarkov.dev/item-1-icon.webp",
          "image512pxLink" => "https://assets.tarkov.dev/item-1-512.webp",
          "image8xLink" => "https://assets.tarkov.dev/item-1-8x.webp",
          "gridImageLink" => "https://assets.tarkov.dev/item-1-grid.webp",
          "wikiLink" => "https://escapefromtarkov.fandom.com/wiki/M4A1"
        }
      },
      "itemCategories" => {
        "cat-1" => { "id" => "cat-1", "normalizedName" => "assault-rifle", "parent" => "cat-parent" },
        "cat-parent" => { "id" => "cat-parent", "normalizedName" => "weapons", "parent" => nil }
      }
    }
  end

  def trader_payload
    {
      "trader-1" => {
        "id" => "trader-1",
        "name" => "Prapor",
        "normalizedName" => "prapor",
        "description" => "Trader description",
        "currency" => "RUB",
        "resetTime" => "2026-08-21T08:40:23.000Z",
        "levels" => [
          { "level" => 1, "requiredPlayerLevel" => 0, "requiredReputation" => 0 },
          { "level" => 2, "requiredPlayerLevel" => 6, "requiredReputation" => 0.7 }
        ]
      }
    }
  end

  def tasks_payload
    {
      "tasks" => {
        "task-1" => {
          "id" => "task-1",
          "name" => "Supplier",
          "trader" => "trader-1",
          "minPlayerLevel" => 5,
          "kappaRequired" => true,
          "lightkeeperRequired" => true,
          "finishRewards" => {
            "items" => [ { "item" => "item-2", "count" => 5000 } ],
            "offerUnlock" => [ { "level" => 4, "item" => "item-1", "trader" => "trader-1" } ],
            "craftUnlock" => []
          },
          "factionName" => "Any",
          "objectives" => [
            { "id" => "obj-1", "type" => "findItem", "items" => [ "item-1" ], "count" => 3, "foundInRaid" => true },
            { "id" => "obj-2", "type" => "visit", "count" => 1 },
            { "id" => "obj-3", "type" => "buildWeapon", "item" => "item-missing", "count" => 1 },
            { "id" => "obj-4", "type" => "findQuestItem", "questItem" => "qitem-9", "count" => 2 }
          ]
        },
        "task-2" => {
          "id" => "task-2",
          "name" => "No trader task",
          "trader" => nil,
          "minPlayerLevel" => 14,
          "kappaRequired" => false,
          "taskRequirements" => [ { "task" => "task-1", "status" => [ "complete" ] } ],
          "objectives" => []
        }
      },
      "questItems" => {
        "qitem-9" => {
          "id" => "qitem-9",
          "name" => "Military Intel",
          "shortName" => "Intel",
          "description" => "Quest item",
          "width" => 1,
          "height" => 1,
          "iconLink" => "https://assets.tarkov.dev/qitem-9-icon.webp"
        }
      }
    }
  end

  def barter_payload
    [
      {
        "id" => "barter-1",
        "trader" => "trader-1",
        "minTraderLevel" => 2,
        "requiredItems" => [ { "item" => "item-1", "count" => 2 } ],
        "offeredItem" => { "item" => "item-2", "count" => 1 }
      },
      {
        "id" => "barter-unlock",
        "trader" => "trader-1",
        "minTraderLevel" => 4,
        "taskUnlock" => "task-1",
        "requiredItems" => [ { "item" => "item-1", "count" => 1 } ],
        "offeredItem" => { "item" => "qitem-9", "count" => 1 }
      },
      {
        "id" => "barter-broken",
        "trader" => "trader-unknown",
        "offeredItem" => { "item" => "item-1", "count" => 1 }
      }
    ]
  end

  def crafts_payload
    [
      {
        "id" => "craft-1",
        "station" => "station-2",
        "level" => 1,
        "duration" => 3600,
        "requiredItems" => [ { "item" => "item-1", "count" => 2 } ],
        "productItem" => { "item" => "item-2", "count" => 1 }
      }
    ]
  end
end
