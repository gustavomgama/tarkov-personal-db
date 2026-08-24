require "test_helper"

class LinkNormalizationTest < ActiveSupport::TestCase
  test "non-http link schemes are dropped on assignment" do
    item = Item.new(tid: "i-1", name: "Item")
    item.wiki_link = "javascript:alert(1)"
    assert_nil item.wiki_link
  end

  test "http(s) links are kept verbatim" do
    task = Task.new(tid: "t-1", name: "Task")
    task.wiki_link = "HTTP://Example.com/Page"
    assert_equal "HTTP://Example.com/Page", task.wiki_link

    trader = Trader.new(tid: "r-1", name: "Trader")
    trader.image_url = "https://assets.tarkov.dev/x.webp"
    assert_equal "https://assets.tarkov.dev/x.webp", trader.image_url
  end

  test "other schemes and blank values become nil" do
    trader = Trader.new(tid: "r-2", name: "Trader")
    trader.image_url = "ftp://nope"
    assert_nil trader.image_url

    item = Item.new(tid: "i-2", name: "Item")
    item.icon_link = ""
    assert_nil item.icon_link
  end
end
