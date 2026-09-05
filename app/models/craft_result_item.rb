# == Schema Information
#
# Table name: craft_result_items
#
#  id              :bigint           not null, primary key
#  craft_result_id :bigint
#  item_id         :string
#  item_name       :string
#
# Indexes
#
#  index_craft_result_items_on_craft_result_id  (craft_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (craft_result_id => craft_results.id)
#
class CraftResultItem < ApplicationRecord
  belongs_to :craft_result, foreign_key: :craft_result_id
end
