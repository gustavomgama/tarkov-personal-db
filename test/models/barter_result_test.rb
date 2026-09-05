require "test_helper"

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
class BarterResultTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
