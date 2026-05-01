class ProjectPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
