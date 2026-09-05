require "test_helper"

# == Schema Information
#
# Table name: barters
#
#  id         :bigint           not null, primary key
#  item_id    :string(36)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class BarterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
