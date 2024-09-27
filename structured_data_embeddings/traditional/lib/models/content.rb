# scripts/lib/content.rb

class Content < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :line_number, presence: true
  validates :text, presence: true
  validates :line_number, uniqueness: { scope: :document_id }
end