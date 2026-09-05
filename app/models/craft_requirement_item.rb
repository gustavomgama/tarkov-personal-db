# == Schema Information
#
# Table name: craft_requirement_items
#
#  id                   :bigint           not null, primary key
#  craft_requirement_id :bigint
#  item_id              :string
#  item_name            :string
#  count                :integer
#
# Indexes
#
#  index_craft_requirement_items_on_craft_requirement_id  (craft_requirement_id)
#
# Foreign Keys
#
#  fk_rails_...  (craft_requirement_id => craft_requirements.id)
#
class CraftRequirementItem < ApplicationRecord
  belongs_to :craft_requirement, foreign_key: :craft_requirement_id
end
