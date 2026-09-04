# == Schema Information
#
# Table name: tasks
#
#  id                   :bigint           not null, primary key
#  bsg_id               :string           not null
#  name                 :string           not null
#  full_name            :string           not null
#  wiki_link            :string           default(""), not null
#  given_by             :string           not null
#  kappa_required       :boolean          default(FALSE), not null
#  lightkeeper_required :boolean          default(FALSE), not null
#  leads_to             :jsonb            not null
#  requirements         :jsonb            not null
#  start_rewards        :jsonb            not null
#  finish_rewards       :jsonb            not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_tasks_on_bsg_id    (bsg_id) UNIQUE
#  index_tasks_on_given_by  (given_by)
#  index_tasks_on_name      (name) UNIQUE
#
class Task < ApplicationRecord
  validates :bsg_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :full_name, presence: true

  belongs_to :trader, foreign_key: :given_by, primary_key: :normalized_name, inverse_of: :tasks, optional: true

  def rewards
    start_rewards + finish_rewards
  end

  def self.from_json(json)
    find_or_initialize_by(bsg_id: json["bsg_id"]).tap do |task|
      task.assign_attributes(
        name: json["name"],
        full_name: json["full_name"],
        wiki_link: json["wiki_link"],
        given_by: json["given_by"],
        kappa_required: json["kappa_required"],
        lightkeeper_required: json["lightkeeper_required"],
        leads_to: json["leads_to"] || [],
        requirements: json["requirements"] || [],
        start_rewards: json["start_rewards"] || [],
        finish_rewards: json["finish_rewards"] || []
      )
    end
  end
end
