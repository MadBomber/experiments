# db/models/speaker.rb
class Speaker < ActiveRecord::Base
  validates :name, presence: true
end
