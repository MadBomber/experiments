class ScenePolicy < ApplicationPolicy
  def index?  = true
  def show?   = authorized_to_view?

  def create?
    return false unless record.project.ready?
    producer? || writer?
  end

  def update?  = producer? || (writer? && record.draft?)
  def destroy? = producer?
  def submit?  = producer? || writer?
  def release? = producer? || director?
  def reject?  = producer? || director?
  def run?     = producer? || director?

  private

  def authorized_to_view?
    return true if producer? || writer? || director? || casting_dir?
    return false unless record.released?
    return true unless actor_user?
    user.actor && record.characters.exists?(id: user.actor.character_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.released
             .joins(:scene_characters)
             .where(scene_characters: { character_id: user.actor.character_ids })
      elsif user.has_role?(:director)
        scope.where(status: %w[ready_for_review released])
      elsif user.has_role?(:writer) || user.has_role?(:producer)
        scope.all
      else
        scope.where(status: "released")
      end
    end
  end
end
