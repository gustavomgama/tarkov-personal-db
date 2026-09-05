require "test_helper"

# == Schema Information
#
# Table name: buyables
#
#  id           :bigint           not null, primary key
#  item_id      :string(36)       not null
#  trader_name  :string           not null
#  trader_level :string
#  currency     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (trader_name => traders.name)
#
class BuyableTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
