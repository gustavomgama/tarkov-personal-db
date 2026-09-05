# == Schema Information
#
# Table name: item_hideouts
#
#  id            :bigint           not null, primary key
#  item_id       :bigint
#  station_name  :string
#  station_level :integer
#  quantity      :integer
#
# Indexes
#
#  index_item_hideouts_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemHideout < ApplicationRecord
  belongs_to :item, foreign_key: :item_id
end
