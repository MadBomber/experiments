class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user   = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false

  private

  def producer?    = user.has_role?(:producer)
  def writer?      = user.has_role?(:writer)
  def director?    = user.has_role?(:director)
  def casting_dir? = user.has_role?(:casting_director)
  def actor_user?  = user.has_role?(:actor)

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end
    def resolve = scope.all
    private
    attr_reader :user, :scope
  end
end
