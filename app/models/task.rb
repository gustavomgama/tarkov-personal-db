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
    return nil if title.blank?

    slug = title.strip.tr(" ", "_")
    where("wiki_link LIKE ?", "%/#{slug}").first || find_by(name: title.strip)
  end
end
