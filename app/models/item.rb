# == Schema Information
#
# Table name: items
#
#  id                     :bigint           not null, primary key
#  bsg_id                 :string           not null
#  slug                   :string           not null
#  full_name              :string           not null
#  short_name             :string
#  types                  :jsonb            not null
#  links                  :jsonb            not null
#  images                 :jsonb            not null
#  properties             :jsonb            not null
#  conflicting_items      :jsonb            not null
#  conflicting_slot_ids   :jsonb            not null
#  conflicting_categories :jsonb            not null
#  obtain_from            :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  buyables               :jsonb            not null
#  barteables             :jsonb            not null
#  craftables             :jsonb            not null
#
# Indexes
#
#  index_items_on_bsg_id  (bsg_id) UNIQUE
#  index_items_on_slug    (slug) UNIQUE
#
class Item < ApplicationRecord
  validates :bsg_id, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  def buyable?
    buyables.any?
  end

  def barters?
    barteables.any?
  end

  def craftable?
    craftables.any?
  end
end
