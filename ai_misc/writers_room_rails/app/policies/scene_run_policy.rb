class SceneRunPolicy < ApplicationPolicy
  def index?  = true
  def show?   = authorized_to_view?
  def create? = producer? || director?

  private

  def authorized_to_view?
    return true if producer? || director? || writer? || casting_dir?
    return false unless actor_user? && user.actor
    record.scene.characters.exists?(id: user.actor.character_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_role?(:actor) && !user.has_role?(:producer)
        return scope.none unless user.actor
        scope.joins(scene: :scene_characters)
             .where(scene_characters: { character_id: user.actor.character_ids })
             .merge(Scene.where(status: "released"))
      else
        scope.all
      end
    end
  end
end
