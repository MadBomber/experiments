# scripts/lib/structure.

class Structure < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :block_name, presence: true
  validates :lines, presence: true
end