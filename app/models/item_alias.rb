# == Schema Information
#
# Table name: item_aliases
#
#  id            :integer          not null, primary key
#  canonical_tid :string           not null
#  tid           :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_item_aliases_on_tid  (tid) UNIQUE
#
# Maps dropped preset/base variants to the canonical weapon entry that
# replaced them (see Tarkov::PresetCollapse), so upstream payloads written
# against old tids keep resolving.
class ItemAlias < ApplicationRecord
  validates :tid, presence: true, uniqueness: true
  validates :canonical_tid, presence: true

  def self.resolve(tid)
    where(tid: tid).pick(:canonical_tid) || tid
  end
end
