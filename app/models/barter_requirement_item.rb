# == Schema Information
#
# Table name: barter_requirement_items
#
#  id                    :bigint           not null, primary key
#  barter_requirement_id :bigint
#  item_id               :string
#  item_name             :string
#  count                 :integer
#
# Indexes
#
#  index_barter_requirement_items_on_barter_requirement_id  (barter_requirement_id)
#
# Foreign Keys
#
#  fk_rails_...  (barter_requirement_id => barter_requirements.id)
#
class BarterRequirementItem < ApplicationRecord
  belongs_to :barter_requirement, foreign_key: :barter_requirement_id
end
