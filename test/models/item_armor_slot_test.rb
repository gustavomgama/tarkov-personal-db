require "test_helper"

# == Schema Information
#
# Table name: item_armor_slots
#
#  id         :bigint           not null, primary key
#  item_id    :string(36)       not null
#  zone       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemArmorSlotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
