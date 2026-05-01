class CastingPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || casting_dir?
  def update?  = producer? || casting_dir?
  def destroy? = producer? || casting_dir?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
