require "test_helper"

# == Schema Information
#
# Table name: item_slot_filters
#
#  id                  :bigint           not null, primary key
#  item_slot_id        :bigint           not null
#  filter_type         :string           not null
#  allowed_items       :text
#  excluded_items      :text
#  allowed_categories  :text
#  excluded_categories :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_slot_id => item_slots.id)
#
class ItemSlotFilterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
