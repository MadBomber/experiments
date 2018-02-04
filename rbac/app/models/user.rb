class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  rolify

  after_create :assign_default_role

  def assign_default_role
    self.add_role('guest') if self.roles.blank?
  end

end
