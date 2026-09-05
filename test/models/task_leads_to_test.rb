require "test_helper"

# == Schema Information
#
# Table name: task_leads_tos
#
#  id               :bigint           not null, primary key
#  task_id          :bigint           not null
#  leads_to_task_id :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (leads_to_task_id => tasks.id)
#  fk_rails_...  (task_id => tasks.id)
#
class TaskLeadsToTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
