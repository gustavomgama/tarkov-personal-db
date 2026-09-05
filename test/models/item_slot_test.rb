require "test_helper"

# == Schema Information
#
# Table name: item_slots
#
#  id              :bigint           not null, primary key
#  item_id         :string(36)       not null
#  name            :string
#  filters_version :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemSlotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
