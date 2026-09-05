require "test_helper"

# == Schema Information
#
# Table name: task_gated_craft_unlocks
#
#  id                  :bigint           not null, primary key
#  task_gated_craft_id :bigint           not null
#  trader_name         :string
#  trader_level        :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (task_gated_craft_id => task_gated_crafts.id)
#
class TaskGatedCraftUnlockTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
