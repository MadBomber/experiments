# scripts/lib/document.rb

class Document < ActiveRecord::Base
  validates :title, presence: true
  validates :filename, presence: true

  has_many :contents, dependent: :destroy
  has_many :embeddings, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :structures, dependent: :destroy
end
