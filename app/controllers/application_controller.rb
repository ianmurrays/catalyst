class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Disable Rails layouts - Phlex handles all layout rendering
  layout false

  include AuthProvider
  include I18nProvider
  include Pundit::Authorization

  before_action :set_current_team
  helper_method :current_team

  # Define pundit_user to include current team context
  def pundit_user
    UserContext.new(current_user, current_team)
  end

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  # Current team for this request
  def current_team
    @current_team
  end

  # Resolve and persist current team context
  def set_current_team
    return unless logged_in?

    # Try session first
    if session[:current_team_id]
      @current_team = current_user.teams.find_by(id: session[:current_team_id])
    end

    # Try cookie if no session match
    if @current_team.nil? && cookies.encrypted[:last_team_id]
      @current_team = current_user.teams.find_by(id: cookies.encrypted[:last_team_id])
    end

    # Fallback: support plain cookie jar (e.g., request specs)
    if @current_team.nil? && cookies[:last_team_id]
      @current_team = current_user.teams.find_by(id: cookies[:last_team_id])
    end

    # Default to first available team
    @current_team ||= current_user.teams.first

    # Update session with resolved team id (or nil)
    session[:current_team_id] = @current_team&.id
  end

  # Require a current team for team-scoped areas
  # Phase 6 will introduce proper onboarding; until then, redirect to teams listing.
  def require_team
    unless current_team
      redirect_to teams_path
    end
  end

  def user_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_to(request.referrer || root_path)
  end
end
