require "test_helper"

# == Schema Information
#
# Table name: task_gated_buyables
#
#  id           :bigint           not null, primary key
#  task_id      :bigint           not null
#  item_id      :string(36)       not null
#  trader_name  :string
#  trader_level :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#  fk_rails_...  (task_id => tasks.id)
#
class TaskGatedBuyableTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
