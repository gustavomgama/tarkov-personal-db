class CraftItem < ApplicationRecord
  belongs_to :hideout_craft
  belongs_to :item

  validates :kind, presence: true, inclusion: { in: HideoutCraft::KINDS }
  validates :item_id, uniqueness: { scope: %i[hideout_craft_id kind] }
end
