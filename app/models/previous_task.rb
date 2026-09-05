# == Schema Information
#
# Table name: previous_tasks
#
#  id             :bigint           not null, primary key
#  requirement_id :bigint
#  task_id        :string
#  task_name      :string
#
# Indexes
#
#  index_previous_tasks_on_requirement_id  (requirement_id)
#
# Foreign Keys
#
#  fk_rails_...  (requirement_id => requirements.id)
#
class PreviousTask < ApplicationRecord
  belongs_to :requirement, foreign_key: :requirement_id
end
