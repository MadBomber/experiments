class StoryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = producer? || writer? || director?
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
