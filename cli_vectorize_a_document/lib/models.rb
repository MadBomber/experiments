# lib/models.rb
# basic bare-bones models for each table
#
# TODO: seperate these models into their own files.
# TODO: move some of the methods from the ETL scripts
#       the models upon which they work.

##########################################
class Document < ActiveRecord::Base
  validates :title, presence: true
  validates :filename, presence: true

  has_many :contents, dependent: :destroy
  has_many :embeddings, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :structures, dependent: :destroy
end


##########################################
class Content < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :line_number, presence: true
  validates :text, presence: true
  validates :line_number, uniqueness: { scope: :document_id }
end


##########################################
class Embedding < ActiveRecord::Base
  # CAUTION: The hardcoded dimensions is based upon
  #           the use of the nomic-embed-text model
  #           if any other embedding model is used
  #           the dimensions will likely change.
  #           This 2048 magic number is also tied to
  #           the SQL file that creates the table.

  has_neighbors :values, dimensions: 2048
  
  belongs_to :document

  validates :document_id, presence: true
  validates :lines, presence: true
  validates :values, presence: true
end


##########################################
class Page < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :page_number, presence: true
  validates :lines, presence: true
end

##########################################
class Structure < ActiveRecord::Base
  belongs_to :document

  validates :document_id, presence: true
  validates :block_name, presence: true
  validates :lines, presence: true
end
