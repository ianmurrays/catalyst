class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Disable Rails layouts - Phlex handles all layout rendering
  layout false

  # Basic security measures
  protect_from_forgery with: :exception

  include AuthProvider
  include I18nProvider
  include Pundit::Authorization

  before_action :set_current_team
  helper_method :current_team, :current_team_id, :current_team_name, :user_has_teams?

  # Define pundit_user to include current team context
  def pundit_user
    UserContext.new(current_user, current_team)
  end

  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Public helper methods for view access
  def current_team_id
    @current_team&.id
  end

  def current_team_name
    @current_team&.name
  end

  def user_has_teams?
    current_user&.teams&.exists?
  end

  private

  # Current team for this request
  def current_team
    @current_team
  end

  # Resolve and persist current team context
  def set_current_team
    return unless logged_in?

    # Try session first (most recent)
    if session[:current_team_id]
      @current_team = current_user.teams.find_by(id: session[:current_team_id])
    end

    # Fallback to cookie preference
    if @current_team.nil? && has_team_preference?
      @current_team = current_user.teams.find_by(id: cookies.encrypted[:last_team_id])
    end

    # Fallback: support plain cookie jar (e.g., request specs)
    if @current_team.nil? && cookies[:last_team_id]
      @current_team = current_user.teams.find_by(id: cookies[:last_team_id])
    end

    # Default to first team
    @current_team ||= current_user.teams.first

    # Update both session and cookie with resolved team
    if @current_team
      session[:current_team_id] = @current_team.id
      store_team_preference(@current_team)
    else
      session[:current_team_id] = nil
    end
  end

  # Store team preference in encrypted cookie
  def store_team_preference(team)
    cookies.encrypted[:last_team_id] = {
      value: team.id,
      expires: 1.year.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  # Clear team preference cookie
  def clear_team_preference
    cookies.delete(:last_team_id)
  end

  # Check if team preference cookie exists
  def has_team_preference?
    cookies.encrypted[:last_team_id].present?
  end

  # Clear all team context (session and cookies)
  def clear_team_context
    session.delete(:current_team_id)
    clear_team_preference
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
