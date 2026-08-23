# == Schema Information
#
# Table name: items
#
#  id              :integer          not null, primary key
#  barter          :boolean          default(FALSE), not null
#  craft           :boolean          default(FALSE), not null
#  currency        :string
#  grid_image_link :string
#  icon_link       :string
#  name            :string           not null
#  price           :integer
#  quest_item      :boolean          default(FALSE), not null
#  require_unlock  :boolean          default(FALSE), not null
#  tid             :string           not null
#  wiki_link       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_items_on_tid  (tid) UNIQUE
#
class Item < ApplicationRecord
  has_many :task_objectives, dependent: :destroy
  has_many :tasks, through: :task_objectives
  has_many :hideout_item_requirements, dependent: :destroy
  has_many :hideout_levels, through: :hideout_item_requirements
  has_many :item_unlocks, dependent: :destroy
  has_many :unlock_tasks, through: :item_unlocks, source: :task
  has_many :task_rewards, dependent: :destroy
  has_many :rewarded_by_tasks, through: :task_rewards, source: :task
  has_many :craft_items, dependent: :destroy

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
