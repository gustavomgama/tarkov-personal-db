# == Schema Information
#
# Table name: craft_items
#
#  id               :integer          not null, primary key
#  count            :integer
#  kind             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hideout_craft_id :integer          not null
#  item_id          :integer          not null
#
# Indexes
#
#  index_craft_items_on_hideout_craft_id  (hideout_craft_id)
#  index_craft_items_on_item_id           (item_id)
#  index_craft_items_uniqueness           (hideout_craft_id,item_id,kind) UNIQUE
#
# Foreign Keys
#
#  hideout_craft_id  (hideout_craft_id => hideout_crafts.id)
#  item_id           (item_id => items.id)
#
class CraftItem < ApplicationRecord
  belongs_to :hideout_craft
  belongs_to :item

  validates :kind, presence: true, inclusion: { in: HideoutCraft::KINDS }
  validates :item_id, uniqueness: { scope: %i[hideout_craft_id kind] }
end
