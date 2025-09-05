module Auth0
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_auth0_user
  end

  def current_auth0_user
    @current_auth0_user ||= session[:userinfo]
  end

  def logged_in?
    session[:userinfo].present?
  end
end
