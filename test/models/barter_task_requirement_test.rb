require "test_helper"

# == Schema Information
#
# Table name: barter_task_requirements
#
#  id         :bigint           not null, primary key
#  barter_id  :bigint           not null
#  task_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (barter_id => barters.id)
#  fk_rails_...  (task_id => tasks.id)
#
class BarterTaskRequirementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
