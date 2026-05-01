class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers
  include Pundit::Authorization

  before_action :require_user!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_user

  allow_browser versions: :modern

  private

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def require_user!
    return if current_user
    redirect_to new_passwordless_session_path(:users),
                alert: "You must be signed in."
  end
end
