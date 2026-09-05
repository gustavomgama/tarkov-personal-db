# == Schema Information
#
# Table name: barter_results
#
#  id               :bigint           not null, primary key
#  barter_unlock_id :bigint
#
# Indexes
#
#  index_barter_results_on_barter_unlock_id  (barter_unlock_id)
#
# Foreign Keys
#
#  fk_rails_...  (barter_unlock_id => barter_unlocks.id)
#
class BarterResult < ApplicationRecord
  belongs_to :barter_unlock, foreign_key: :barter_unlock_id
  has_many :barter_result_items, dependent: :destroy
end
