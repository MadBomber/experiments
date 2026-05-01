class Role < ApplicationRecord
  NAMES = %w[producer writer director casting_director actor].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true,
                   uniqueness: true,
                   inclusion: { in: NAMES }
end
