require "test_helper"

# == Schema Information
#
# Table name: craft_task_requirements
#
#  id         :bigint           not null, primary key
#  craft_id   :bigint           not null
#  task_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (craft_id => crafts.id)
#  fk_rails_...  (task_id => tasks.id)
#
class CraftTaskRequirementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
