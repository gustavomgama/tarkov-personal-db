require "test_helper"

# == Schema Information
#
# Table name: items
#
#  id                     :bigint           not null, primary key
#  bsg_id                 :string           not null
#  slug                   :string           not null
#  full_name              :string           not null
#  short_name             :string
#  types                  :jsonb            not null
#  links                  :jsonb            not null
#  images                 :jsonb            not null
#  properties             :jsonb            not null
#  conflicting_items      :jsonb            not null
#  conflicting_slot_ids   :jsonb            not null
#  conflicting_categories :jsonb            not null
#  obtain_from            :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  buyables               :jsonb            not null
#  barteables             :jsonb            not null
#  craftables             :jsonb            not null
#
# Indexes
#
#  index_items_on_bsg_id  (bsg_id) UNIQUE
#  index_items_on_slug    (slug) UNIQUE
#
class ItemTest < ActiveSupport::TestCase
  test "persists item fields" do
    item = items(:factory_emergency_exit_key)
    assert_equal "5448ba0b4bdc2d02308b456c", item.bsg_id
    assert_equal "factory-emergency-exit-key", item.slug
    assert_equal "Factory emergency exit key", item.full_name
    assert_equal "Factory", item.short_name
  end

  test "buyables returns array" do
    item = items(:rgd_5_hand_grenade)
    assert_equal Array, item.buyables.class
  end

  test "barteables returns array" do
    item = items(:factory_emergency_exit_key)
    assert_equal Array, item.barteables.class
  end

  test "craftables returns array" do
    item = items(:factory_emergency_exit_key)
    assert_equal Array, item.craftables.class
  end

  test "buyable? returns boolean" do
    buyable_item = items(:rgd_5_hand_grenade)
    non_buyable_item = items(:factory_emergency_exit_key)
    assert_equal true, buyable_item.buyable?
    assert_equal false, non_buyable_item.buyable?
    assert_equal [ TrueClass, FalseClass ], [ buyable_item.buyable?, non_buyable_item.buyable? ].map(&:class).uniq
  end
end
