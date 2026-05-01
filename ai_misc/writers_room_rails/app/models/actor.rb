class Actor < ApplicationRecord
  has_many :castings, dependent: :destroy
  has_many :characters, through: :castings
  has_many :projects,   through: :castings
  has_one  :user

  validates :name, presence: true
end
