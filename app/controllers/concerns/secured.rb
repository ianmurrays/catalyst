module Secured
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  private

  def require_authentication
    unless logged_in?
      session[:return_to] = request.fullpath
      redirect_to "/auth/auth0", allow_other_host: true
    end
  end
end
