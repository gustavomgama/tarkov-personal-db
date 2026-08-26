require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "tk_money formats whole prices" do
    item = Item.new(price: 6500, currency: "RUB")

    assert_equal "6,500 RUB", tk_money(item)
    assert_nil tk_money(Item.new)
  end

  test "trader_avatar falls back to an initial chip without a portrait" do
    trader = Trader.new(name: "Prapor", tid: "t-1")

    html = trader_avatar(trader)

    assert_includes html, "trader-avatar-fallback"
    assert_includes html, "P"
    assert_equal html, trader_avatar("Prapor")
  end

  test "dev_trader_link derives the slug from the name when missing" do
    trader = Trader.new(name: "Ref", slug: nil)

    assert_match %r{href="https://tarkov\.dev/trader/ref"}, dev_trader_link(trader)
  end

  test "ingredient_icon falls back to the stored remote icon" do
    html = ingredient_icon({ "tid" => "abc", "name" => "Gold", "icon_link" => "https://assets.example/x.png" })

    assert_includes html, "https://assets.example/x.png"
    assert_nil ingredient_icon({ "tid" => "abc", "name" => "Nope" })
  end

  test "offer_verb maps unlock types to player language" do
    assert_equal "Buy from", offer_verb("money")
    assert_equal "Barter at", offer_verb("barter")
    assert_equal "Craft at", offer_verb("craft")
    assert_equal "Get from", offer_verb("mystery")
  end

  test "trader_link degrades to plain text for unknown traders" do
    html = trader_link("Ghost Trader")

    assert_includes html, "<span>Ghost Trader</span>"
    refute_includes html, "<a "
  end

  test "gp coin ingredients are detected by tid or name" do
    assert gp_coin?({ "tid" => ApplicationHelper::GP_COIN_TID, "name" => "GP coin" })
    assert gp_coin?({ "tid" => "other", "name" => "GP coin" })
    refute gp_coin?({ "tid" => "x", "name" => "Graphics card" })
  end

  test "offer badges separate GP purchases and quest rewards from barters" do
    assert_equal %w[accent GP COINS], offer_badge({ type: "money", gp_currency: true })
    assert_equal %w[accent GP COINS], offer_badge({ type: "barter", gp_currency: false,
                                                    required_items: [ { "tid" => ApplicationHelper::GP_COIN_TID } ] })
    assert_equal %w[accent REWARD], offer_badge({ type: "reward" })
    assert_equal %w[info BARTER], offer_badge({ type: "barter", required_items: [] })
    assert_equal %w[success BUY], offer_badge({ type: "money" })
  end

  test "local_image serves the downloaded copy when present" do
    dir = Rails.root.join("public/images/items")
    dir.mkpath
    File.write(dir.join("test-tid-icon.webp"), "")

    assert_equal "/images/items/test-tid-icon.webp", send(:local_image, "items", "test-tid", "-icon")
    assert_nil send(:local_image, "items", "missing-tid", "-icon")
  ensure
    File.delete(dir.join("test-tid-icon.webp")) if File.exist?(dir.join("test-tid-icon.webp"))
  end
end
