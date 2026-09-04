require "test_helper"

# == Schema Information
#
# Table name: traders
#
#  id              :bigint           not null, primary key
#  bsg_id          :string           not null
#  name            :string           not null
#  normalized_name :string           not null
#  image_link      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  buyables        :jsonb            not null
#  barteables      :jsonb            not null
#
# Indexes
#
#  index_traders_on_bsg_id           (bsg_id) UNIQUE
#  index_traders_on_normalized_name  (normalized_name) UNIQUE
#
class TraderTest < ActiveSupport::TestCase
  test "persists trader fields" do
    trader = traders(:ragman)
    assert_equal "5ac3b934156ae10c4430e83c", trader.bsg_id
    assert_equal "Ragman", trader.name
    assert_equal "ragman", trader.normalized_name
    assert_equal "https://assets.tarkov.dev/5ac3b934156ae10c4430e83c.webp", trader.image_link
  end

  test "tasks association" do
    trader = traders(:ragman)
    assert_equal 1, trader.tasks.count
    assert_equal "a-big-loss", trader.tasks.first.name
  end

  test "buyables returns array" do
    trader = traders(:prapor)
    assert_equal Array, trader.buyables.class
    assert trader.buyables.length > 0
  end

  test "barteables returns array" do
    trader = traders(:prapor)
    assert_equal Array, trader.barteables.class
  end

  test "buyables contains expected structure" do
    trader = traders(:prapor)
    buyable = trader.buyables.first
    assert_equal "prapor", buyable["trader_name"]
    assert_equal "RUB", buyable["currency"]
  end
end
