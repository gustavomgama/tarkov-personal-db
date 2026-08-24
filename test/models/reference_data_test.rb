require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "validates tid uniqueness and name presence" do
    Item.create!(tid: "x", name: "Item")
    duplicate = Item.new(tid: "x", name: "Other")

    assert_predicate duplicate, :invalid?
    assert_not_empty duplicate.errors[:tid]

    anonymous = Item.new(tid: "y")
    assert_predicate anonymous, :invalid?
    assert_not_empty anonymous.errors[:name]
  end

  test "acquisition flags default to false" do
    item = Item.create!(tid: "x", name: "Item")

    assert_not item.barter?
    assert_not item.craft?
    assert_not item.require_unlock?
    assert_nil item.price
    assert_nil item.currency
  end
end

class TraderTest < ActiveSupport::TestCase
  test "keeps reset time when payload omits it" do
    trader = Trader.create!(tid: "t", name: "Prapor")

    assert_nil trader.reset_time
  end
end
