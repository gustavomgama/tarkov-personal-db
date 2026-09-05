require "test_helper"

# == Schema Information
#
# Table name: task_rewards
#
#  id          :bigint           not null, primary key
#  task_id     :bigint           not null
#  reward_type :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (task_id => tasks.id)
#
class TaskRewardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
