class Task < ApplicationRecord
  belongs_to :trader, optional: true

  has_many :task_objectives, dependent: :destroy
  has_many :items, through: :task_objectives
  has_many :task_requirements, dependent: :destroy, foreign_key: :task_id
  has_many :required_tasks, through: :task_requirements, source: :required_task
  has_many :unlocked_by_requirements, class_name: "TaskRequirement", foreign_key: :required_task_id, dependent: :destroy
  has_many :unlocking_tasks, through: :unlocked_by_requirements, source: :task

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
  # `previous` link when tarkov.dev carries no taskRequirements.
  def prerequisite_tasks
    return required_tasks if required_tasks.any?
    return Task.none if previous_task_title.blank?

    Task.where(id: Array(Task.find_by_wiki_title(previous_task_title)).map(&:id))
  end
end
