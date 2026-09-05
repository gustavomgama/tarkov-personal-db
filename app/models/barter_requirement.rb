# == Schema Information
#
# Table name: barter_requirements
#
#  id               :bigint           not null, primary key
#  barter_unlock_id :bigint
#  trader_name      :string
#  trader_level     :string
#
# Indexes
#
#  index_barter_requirements_on_barter_unlock_id  (barter_unlock_id)
#
# Foreign Keys
#
#  fk_rails_...  (barter_unlock_id => barter_unlocks.id)
#
class BarterRequirement < ApplicationRecord
  belongs_to :barter_unlock, foreign_key: :barter_unlock_id
  has_many :barter_requirement_items, dependent: :destroy
end
