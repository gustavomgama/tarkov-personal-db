# == Schema Information
#
# Table name: tasks
#
#  id                   :bigint           not null, primary key
#  bsg_id               :string           default(""), not null
#  full_name            :string           not null
#  name                 :string           default(""), not null
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
#  index_tasks_on_bsg_id                (bsg_id) UNIQUE WHERE ((bsg_id)::text <> ''::text)
#  index_tasks_on_full_name             (full_name)
#  index_tasks_on_given_by              (given_by)
#  index_tasks_on_kappa_required        (kappa_required)
#  index_tasks_on_lightkeeper_required  (lightkeeper_required)
#  index_tasks_on_name                  (name) UNIQUE WHERE ((name)::text <> ''::text)
#
class Task < ApplicationRecord
  # Mirrors offlinedata/tarkovunlockables/tasks_index.json (see ADR-0001).
  # Scalar fields map 1:1 to columns; nested arrays live in JSONB columns.

  validates :full_name, presence: true
  validates :given_by, presence: true
  validate :json_columns_are_arrays

  # Human-readable name is required; the slug (name) and bsg_id (from `id`)
  # may be blank in the source data (Ref-given tasks often lack them).
  scope :named, -> { where.not(name: "") }
  scope :with_bsg_id, -> { where.not(bsg_id: "") }
  scope :kappa, -> { where(kappa_required: true) }
  scope :lightkeeper, -> { where(lightkeeper_required: true) }
  scope :by_given_by, ->(trader) { where(given_by: trader) }

  def slug
    name.presence
  end

  private

  def json_columns_are_arrays
    %i[leads_to requirements start_rewards finish_rewards].each do |col|
      value = public_send(col)
      if value.present? && !value.is_a?(Array)
        errors.add(col, "must be an array")
      end
    end
  end
end
