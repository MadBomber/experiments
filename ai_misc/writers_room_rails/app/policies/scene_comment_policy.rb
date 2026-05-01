class SceneCommentPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = true  # any logged-in user can comment
  def update?  = producer? || record.user_id == user.id
  def destroy? = producer? || record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
