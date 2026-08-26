# == Schema Information
#
# Table name: items
#
#  id             :integer          not null, primary key
#  allowed_ammo   :text             default("[]"), not null
#  ammo           :boolean          default(FALSE), not null
#  barter         :boolean          default(FALSE), not null
#  caliber        :string
#  categories     :text
#  compat         :text             default("{}"), not null
#  craft          :boolean          default(FALSE), not null
#  currency       :string
#  gun            :boolean          default(FALSE), not null
#  icon_link      :string
#  image_link     :string
#  name           :string           not null
#  price          :decimal(14, 2)
#  ref_gp         :boolean          default(FALSE), not null
#  require_unlock :boolean          default(FALSE), not null
#  slug           :string
#  tid            :string           not null
#  wiki_link      :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_items_on_currency    (currency)
#  index_items_on_lower_name  (LOWER(name))
#  index_items_on_price       (price)
#  index_items_on_ref_gp      (ref_gp)
#  index_items_on_slug        (slug)
#  index_items_on_tid         (tid) UNIQUE
#
class Item < ApplicationRecord
  normalizes :wiki_link, :icon_link, with: ApplicationRecord::HTTP_LINK

  serialize :allowed_ammo, coder: JSON
  serialize :categories, coder: JSON
  serialize :compat, coder: JSON

  has_many :item_unlocks, dependent: :destroy

  # Single source of truth for item categories: filter keys and display labels.
  CATEGORIES = {
    "ammo" => "Ammo",
    "gun" => "Gun",
    "helmet" => "Helmet",
    "armor" => "Armor",
    "armored rig" => "Armored rig",
    "rig" => "Rig",
    "backpack" => "Backpack",
    "headset_earpiece" => "Headset / earpiece",
    "medical" => "Medical",
    "grenades" => "Grenades",
    "provisions" => "Provisions",
    "gun_parts" => "Gun parts",
    "wearable_parts" => "Wearable parts",
    "containers" => "Containers",
    "others" => "Others"
  }.freeze

  scope :in_category, ->(key) { where("categories LIKE ?", "%\"#{key}\"%") }

  scope :gated_for, ->(trader) do
    joins(:item_unlocks).where(item_unlocks: { trader_id: trader.id })
                        .where.not(item_unlocks: { task_id: nil }).distinct.order(:name)
  end

  scope :sold_by, ->(trader) do
    joins(:item_unlocks).where(item_unlocks: { trader_id: trader.id, task_id: nil })
                        .distinct.order(price: :desc)
  end

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, allow_nil: true

  # Finds by tid, following preset-collapse aliases when the exact row was
  # merged into a canonical weapon.
  def self.find_canonical(tid)
    find_by(tid: ItemAlias.resolve(tid))
  end

  # Friendly URLs: /items/colt-m4a1-556x45-assault-rifle-carbine
  def to_param
    slug.presence || id.to_s
  end
end
