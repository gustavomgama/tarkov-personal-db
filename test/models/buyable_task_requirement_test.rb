require "test_helper"

# == Schema Information
#
# Table name: buyable_task_requirements
#
#  id         :bigint           not null, primary key
#  buyable_id :bigint           not null
#  task_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (buyable_id => buyables.id)
#  fk_rails_...  (task_id => tasks.id)
#
class BuyableTaskRequirementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
