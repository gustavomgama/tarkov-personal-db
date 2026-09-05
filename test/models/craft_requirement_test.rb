require "test_helper"

# == Schema Information
#
# Table name: craft_requirements
#
#  id              :bigint           not null, primary key
#  craft_unlock_id :bigint
#  trader_name     :string
#  trader_level    :string
#
# Indexes
#
#  index_craft_requirements_on_craft_unlock_id  (craft_unlock_id)
#
# Foreign Keys
#
#  fk_rails_...  (craft_unlock_id => craft_unlocks.id)
#
class CraftRequirementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
