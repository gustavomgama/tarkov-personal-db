require "test_helper"

# == Schema Information
#
# Table name: craft_results
#
#  id              :bigint           not null, primary key
#  craft_unlock_id :bigint
#
# Indexes
#
#  index_craft_results_on_craft_unlock_id  (craft_unlock_id)
#
# Foreign Keys
#
#  fk_rails_...  (craft_unlock_id => craft_unlocks.id)
#
class CraftResultTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
