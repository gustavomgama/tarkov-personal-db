class HideoutRequirement < ApplicationRecord
  belongs_to :hideout_level

  validates :requirement_type, presence: true, inclusion: { in: %w[station trader skill] }
  validates :target_name, presence: true
  validates :target_name, uniqueness: { scope: %i[hideout_level_id requirement_type] }
end
