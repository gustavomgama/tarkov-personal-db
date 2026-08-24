# == Schema Information
#
# Table name: traders
#
#  id         :integer          not null, primary key
#  image_url  :string
#  name       :string           not null
#  reset_time :datetime
#  tid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_traders_on_tid  (tid) UNIQUE
#
class Trader < ApplicationRecord
  has_many :tasks, dependent: :nullify
  has_many :trader_loyalty_levels, dependent: :destroy
  has_many :item_unlocks, dependent: :nullify

  validates :tid, presence: true, uniqueness: true
  validates :name, presence: true
end
