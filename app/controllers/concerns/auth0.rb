module Auth0
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_auth0_user
    helper_method :current_user
  end

  def current_auth0_user
    @current_auth0_user ||= session[:userinfo]
  end

  def current_user
    return nil unless logged_in?

    @current_user ||= User.find_or_create_from_auth0(current_auth0_user)
  end

  def logged_in?
    session[:userinfo].present?
  end
end
