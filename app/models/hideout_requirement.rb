# == Schema Information
#
# Table name: hideout_requirements
#
#  id               :integer          not null, primary key
#  level            :integer
#  requirement_type :string           not null
#  target_name      :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hideout_level_id :integer          not null
#
# Indexes
#
#  idx_on_hideout_level_id_requirement_type_target_nam_12c2b17ea3  (hideout_level_id,requirement_type,target_name) UNIQUE
#  index_hideout_requirements_on_hideout_level_id                  (hideout_level_id)
#
# Foreign Keys
#
#  hideout_level_id  (hideout_level_id => hideout_levels.id)
#
class HideoutRequirement < ApplicationRecord
  belongs_to :hideout_level

  validates :requirement_type, presence: true, inclusion: { in: %w[station trader skill] }
  validates :target_name, presence: true
  validates :target_name, uniqueness: { scope: %i[hideout_level_id requirement_type] }
end
