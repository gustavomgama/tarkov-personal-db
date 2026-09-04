# == Schema Information
#
# Table name: traders
#
#  id              :bigint           not null, primary key
#  bsg_id          :string           not null
#  name            :string           not null
#  normalized_name :string           not null
#  image_link      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  buyables        :jsonb            not null
#  barteables      :jsonb            not null
#
# Indexes
#
#  index_traders_on_bsg_id           (bsg_id) UNIQUE
#  index_traders_on_normalized_name  (normalized_name) UNIQUE
#
class Trader < ApplicationRecord
  validates :bsg_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :normalized_name, presence: true, uniqueness: true

  has_many :tasks, foreign_key: :given_by, primary_key: :normalized_name, inverse_of: :trader
end
