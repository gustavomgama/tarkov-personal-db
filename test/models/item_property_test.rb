require "test_helper"

# == Schema Information
#
# Table name: item_properties
#
#  id                 :bigint           not null, primary key
#  item_id            :string(36)       not null
#  properties_type    :string
#  ammo_type          :string
#  caliber            :string
#  class              :string
#  damage             :string
#  penetration_power  :string
#  default_ammo       :string
#  fire_rate          :string
#  effective_distance :string
#  recoil             :string
#  ergonomics         :string
#  magazine_capacity  :string
#  slotsjson          :text
#  default_preset     :string
#  allowed_ammojson   :text
#  armor_type         :string
#  zonesjson          :text
#  armor_slotsjson    :text
#  base_item          :string
#  slot_count         :string
#  gridsjson          :text
#  recall_type        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (item_id => items.id)
#
class ItemPropertyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
