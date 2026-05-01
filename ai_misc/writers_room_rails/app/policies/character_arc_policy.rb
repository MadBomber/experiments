class CharacterArcPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = producer? || writer?
  def update?  = producer? || writer?
  def destroy? = producer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.where(character_id: user.actor.character_ids)
      else
        scope.all
      end
    end
  end
end
