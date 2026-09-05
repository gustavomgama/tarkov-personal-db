require "test_helper"

# == Schema Information
#
# Table name: items
#
#  id         :bigint           not null, primary key
#  bsg_id     :string
#  slug       :string
#  full_name  :string
#  short_name :string
#  categories :text             default([]), is an Array
#  links      :text             default([]), is an Array
#  images     :text             default([]), is an Array
#
class ItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
