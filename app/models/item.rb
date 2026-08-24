# == Schema Information
#
# Table name: items
#
#  id             :integer          not null, primary key
#  allowed_ammo   :text             default("[]"), not null
#  ammo           :boolean          default(FALSE), not null
#  barter         :boolean          default(FALSE), not null
#  caliber        :string
#  craft          :boolean          default(FALSE), not null
#  currency       :string
#  gun            :boolean          default(FALSE), not null
#  icon_link      :string
#  name           :string           not null
#  price          :decimal(14, 2)
#  require_unlock :boolean          default(FALSE), not null
#  tid            :string           not null
#  wiki_link      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_items_on_tid  (tid) UNIQUE
#
class Item < ApplicationRecord
  normalizes :wiki_link, :icon_link, with: ApplicationRecord::HTTP_LINK

  serialize :allowed_ammo, coder: JSON

  has_many :item_unlocks, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
