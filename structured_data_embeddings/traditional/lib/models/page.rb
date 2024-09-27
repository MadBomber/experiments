# scripts/lib/page.rb

class Page < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :page_number, presence: true
  validates :lines, presence: true
end