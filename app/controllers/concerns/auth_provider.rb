module AuthProvider
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_auth_provider_user
    helper_method :current_user
  end

  def current_auth_provider_user
    @current_auth_provider_user ||= session[:userinfo]
  end

  def current_user
    return nil unless logged_in?

    @current_user ||= User.find_or_create_from_auth_provider(current_auth_provider_user)
  end

  def logged_in?
    session[:userinfo].present?
  end
end
