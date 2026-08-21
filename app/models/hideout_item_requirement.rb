class HideoutItemRequirement < ApplicationRecord
  belongs_to :hideout_level
  belongs_to :item

  validates :hideout_level_id, uniqueness: { scope: :item_id }
end
