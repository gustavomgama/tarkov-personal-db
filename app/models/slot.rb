# == Schema Information
#
# Table name: slots
#
#  id                  :bigint           not null, primary key
#  property_id         :bigint
#  name_id             :string
#  required            :boolean
#  allowed_items       :text             default([]), is an Array
#  allowed_categories  :text             default([]), is an Array
#  excluded_categories :text             default([]), is an Array
#  excluded_items      :text             default([]), is an Array
#
# Indexes
#
#  index_slots_on_property_id  (property_id)
#
# Foreign Keys
#
#  fk_rails_...  (property_id => properties.id)
#
class Slot < ApplicationRecord
  belongs_to :property, foreign_key: :property_id
end
