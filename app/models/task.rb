# == Schema Information
#
# Table name: tasks
#
#  id                   :integer          not null, primary key
#  kappa_required       :boolean          default(FALSE)
#  lightkeeper_required :boolean          default(FALSE), not null
#  min_player_level     :integer
#  name                 :string           not null
#  next_task_name       :string
#  previous_task_name   :string
#  tid                  :string           not null
#  wiki_link            :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  next_task_id         :integer
#  previous_task_id     :integer
#  trader_id            :integer
#
# Indexes
#
#  index_tasks_on_tid        (tid) UNIQUE
#  index_tasks_on_trader_id  (trader_id)
#
# Foreign Keys
#
#  trader_id  (trader_id => traders.id)
#
class Task < ApplicationRecord
  belongs_to :trader, optional: true

  has_many :task_requirements, dependent: :destroy, foreign_key: :task_id
  has_many :required_tasks, through: :task_requirements, source: :required_task
  has_many :unlocked_by_requirements, class_name: "TaskRequirement", foreign_key: :required_task_id, dependent: :destroy
  has_many :unlocking_tasks, through: :unlocked_by_requirements, source: :task
  has_many :item_unlocks, foreign_key: :task_id, dependent: :destroy
  has_many :unlocked_items, through: :item_unlocks, source: :item

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true

  def self.find_by_wiki_title(title)
    candidates = title.to_s.strip.gsub(/\.+\z/, "").split("/").map(&:strip).reject(&:blank?)
    candidates.each do |candidate|
      slug = candidate.tr(" ", "_")
      found = where("wiki_link LIKE ?", "%/#{slug}").first || find_by(name: candidate)
      return found if found
    end
    nil
  end

  # Wiki is authoritative for chains: fall back to the quest infobox
  # `previous` link (already resolved into previous_task_id) when tarkov.dev
  # carries no taskRequirements.
  def prerequisite_tasks
    return required_tasks if required_tasks.any?
    return Task.none if previous_task_id.blank?

    Task.where(id: previous_task_id)
  end

  def next_task
    @next_task ||= Task.find_by(id: next_task_id)
  end
end
