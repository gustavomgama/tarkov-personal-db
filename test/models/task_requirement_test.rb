require "test_helper"

# == Schema Information
#
# Table name: task_requirements
#
#  id                :bigint           not null, primary key
#  task_id           :bigint           not null
#  requirement_type  :string
#  trader_name       :string           not null
#  trader_level      :string
#  task_require_id   :bigint
#  task_require_name :string
#  required_quests   :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#  fk_rails_...  (trader_name => traders.name)
#
class TaskRequirementTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
