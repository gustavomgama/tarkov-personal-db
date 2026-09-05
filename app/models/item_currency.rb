# == Schema Information
#
# Table name: item_currencies
#
#  id           :bigint           not null, primary key
#  item_id      :bigint
#  trader_name  :string
#  trader_level :string
#  currency     :string
#
# Indexes
#
#  index_item_currencies_on_item_id  (item_id)
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemCurrency < ApplicationRecord
  belongs_to :item, foreign_key: :item_id
end
