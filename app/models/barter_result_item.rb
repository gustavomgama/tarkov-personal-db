# == Schema Information
#
# Table name: barter_result_items
#
#  id               :bigint           not null, primary key
#  barter_result_id :bigint
#  item_id          :string
#  item_name        :string
#
# Indexes
#
#  index_barter_result_items_on_barter_result_id  (barter_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (barter_result_id => barter_results.id)
#
class BarterResultItem < ApplicationRecord
  belongs_to :barter_result, foreign_key: :barter_result_id
end
