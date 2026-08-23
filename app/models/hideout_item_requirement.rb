# == Schema Information
#
# Table name: hideout_item_requirements
#
#  id               :integer          not null, primary key
#  count            :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hideout_level_id :integer          not null
#  item_id          :integer          not null
#
# Indexes
#
#  idx_on_hideout_level_id_item_id_f9738f0439           (hideout_level_id,item_id) UNIQUE
#  index_hideout_item_requirements_on_hideout_level_id  (hideout_level_id)
#  index_hideout_item_requirements_on_item_id           (item_id)
#
# Foreign Keys
#
#  hideout_level_id  (hideout_level_id => hideout_levels.id)
#  item_id           (item_id => items.id)
#
class HideoutItemRequirement < ApplicationRecord
  belongs_to :hideout_level
  belongs_to :item

  validates :hideout_level_id, uniqueness: { scope: :item_id }
end
