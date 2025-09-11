class TeamSwitchController < ApplicationController
  include AuthProvider
  include Secured

  before_action :find_team, only: [ :update ]
  before_action :authorize_team_access, only: [ :update ]

  def update
    begin
      switch_to_team(@team)

      respond_to do |format|
        format.html { redirect_to after_switch_path }
        format.json { render json: { status: "success", team: team_data } }
      end
    rescue TeamSwitchError => e
      handle_switch_error(e)
    end
  end

  private

  def find_team
    @team = Team.find(params[:team_id])
  rescue ActiveRecord::RecordNotFound
    handle_team_not_found and return
  end

  def authorize_team_access
    return unless @team

    # Use existing Pundit pattern for consistency
    authorize @team, :switch?
  rescue Pundit::NotAuthorizedError
    handle_unauthorized_access and return
  end

  def switch_to_team(team)
    # Update session
    session[:current_team_id] = team.id

    # Update persistent preference
    store_team_preference(team)

    # Log the switch for audit trail
    log_team_switch(team)

    # Clear any cached team data
    clear_team_cache

    # Clear any cached Pundit user context per Pundit docs
    pundit_reset!

    # Add success flash message
    flash[:notice] = t("teams.notifications.switch_success", team_name: team.name)
  end

  def after_switch_path
    # Priority order for redirect:
    # 1. Explicit return_to parameter
    # 2. Referrer (if same-site)
    # 3. Teams listing
    # 4. Root path

    return params[:return_to] if params[:return_to].present? && safe_redirect?(params[:return_to])
    return request.referrer if request.referrer.present? && same_site_referrer?
    return teams_path if respond_to?(:teams_path)
    root_path
  end

  def log_team_switch(team)
    Rails.logger.info "User #{current_user.id} switched to team #{team.id} (#{team.name})"

    # Could be enhanced with audit log model:
    # AuditLog.create!(
    #   user: current_user,
    #   action: 'team_switch',
    #   resource: team,
    #   metadata: { previous_team_id: session[:current_team_id] }
    # )
  end

  def clear_team_cache
    # Clear any request-level team caching
    remove_instance_variable(:@current_team) if defined?(@current_team)
  end

  def team_data
    {
      id: @team.id,
      name: @team.name,
      role: current_user.memberships.find_by(team: @team)&.role
    }
  end

  # Error handling methods
  def handle_team_not_found
    respond_to do |format|
      format.html do
        redirect_to teams_path,
                    alert: t("teams.errors.team_not_found") and return
      end
      format.json do
        render json: { error: t("teams.errors.team_not_found") },
               status: :not_found and return
      end
    end
  end

  def handle_unauthorized_access
    respond_to do |format|
      format.html do
        redirect_to root_path,
                    alert: t("teams.errors.unauthorized_switch") and return
      end
      format.json do
        render json: { error: t("teams.errors.unauthorized_switch") },
               status: :forbidden and return
      end
    end
  end

  def handle_switch_error(error)
    Rails.logger.error "Team switch error: #{error.message}"

    respond_to do |format|
      format.html do
        redirect_to teams_path,
                    alert: t("teams.errors.switch_failed")
      end
      format.json do
        render json: { error: t("teams.errors.switch_failed") },
               status: :unprocessable_entity
      end
    end
  end

  # Security helpers
  def safe_redirect?(url)
    # Only allow relative URLs or same-origin URLs
    uri = URI.parse(url)
    uri.relative? || uri.host == request.host
  rescue URI::InvalidURIError
    false
  end

  def same_site_referrer?
    return false unless request.referrer

    referrer_uri = URI.parse(request.referrer)
    # If it's a relative URL (no host), it's considered same-site
    # If it has a host, check it matches our host
    referrer_uri.host.nil? || referrer_uri.host == request.host
  rescue URI::InvalidURIError
    false
  end
end

# Custom error classes
class TeamSwitchError < StandardError; end
