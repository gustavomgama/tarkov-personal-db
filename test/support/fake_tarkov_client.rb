class FakeTarkovClient
  ENDPOINTS = %w[items tasks traders barters hideout].freeze

  attr_reader :requested

  def initialize(items: { "items" => {}, "itemCategories" => {} },
                 tasks: { "tasks" => {} },
                 traders: {},
                 barters: [],
                 hideout: {})
    @payloads = { "items" => items, "tasks" => tasks, "traders" => traders, "barters" => barters, "hideout" => hideout }
    @requested = []
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
          "name" => "Colt M4A1",
          "shortName" => "M4A1",
          "description" => "Assault rifle",
          "types" => [ "gun" ],
          "categories" => [ "cat-1", "cat-parent" ],
          "weight" => 3.1,
          "width" => 4,
          "height" => 2,
          "iconLink" => "https://assets.tarkov.dev/item-1-icon.webp",
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
        "resetTime" => "2026-08-21T08:40:23.000Z"
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
          "objectives" => [
            { "id" => "obj-1", "type" => "findItem", "items" => [ "item-1" ], "count" => 3, "foundInRaid" => true },
            { "id" => "obj-2", "type" => "visit", "count" => 1 },
            { "id" => "obj-3", "type" => "buildWeapon", "item" => "item-missing", "count" => 1 }
          ]
        },
        "task-2" => {
          "id" => "task-2",
          "name" => "No trader task",
          "trader" => nil,
          "minPlayerLevel" => nil,
          "kappaRequired" => false,
          "objectives" => []
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
        "id" => "barter-broken",
        "trader" => "trader-unknown",
        "offeredItem" => { "item" => "item-1", "count" => 1 }
      }
    ]
  end

  def hideout_payload
    {
      "station-1" => {
        "id" => "station-1",
        "name" => "Generator",
        "normalizedName" => "generator",
        "levels" => [
          {
            "level" => 1,
            "constructionTime" => 60,
            "description" => "Basic generator",
            "itemRequirements" => [
              { "id" => "req-1", "item" => "item-1", "count" => 2 }
            ],
            "stationLevelRequirements" => [
              { "id" => "sreq-1", "station" => "station-2", "level" => 2 }
            ],
            "traderRequirements" => [
              { "id" => "treq-1", "trader" => "trader-1", "value" => 3 }
            ],
            "skillRequirements" => [
              { "id" => "kreq-1", "skill" => "HideoutManagement", "level" => 5 }
            ]
          }
        ]
      },
      "station-2" => {
        "id" => "station-2",
        "name" => "Water Collector",
        "normalizedName" => "water-collector",
        "levels" => []
      }
    }
  end
end
