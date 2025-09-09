class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Disable Rails layouts - Phlex handles all layout rendering
  layout false

  include AuthProvider
  include I18nProvider
  include Pundit::Authorization

  # Define pundit_user to include current team context
  def pundit_user
    UserContext.new(current_user, current_team)
  end

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  # Placeholder for current team - will be implemented in Phase 5
  def current_team
    nil
  end

  def user_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_to(request.referrer || root_path)
  end
end
