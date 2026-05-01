class ActorPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer? || casting_dir?
  def update?  = producer? || writer? || casting_dir?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        scope.where(id: user.actor_id)
      else
        scope.all
      end
    end
  end
end
