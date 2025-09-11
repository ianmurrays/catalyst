# frozen_string_literal: true

module TeamContext
  extend ActiveSupport::Concern

  included do
    include AuthProvider # Ensure we have access to authentication
    before_action :require_team
    helper_method :team_scoped_path, :current_user_role, :can_manage_team?, :can_edit_team_settings?
  end

  def team_scoped_path(path)
    # Helper to generate paths with team context
    # e.g., /teams/1/projects instead of /projects
    return path unless current_team

    case path
    when String
      "/teams/#{current_team.id}#{path}"
    when Symbol
      # Handle named routes with team scope
      url_for(controller: path, team_id: current_team.id)
    else
      path
    end
  end

  def current_user_role
    return nil unless current_team && logged_in?

    membership = current_user.memberships.find_by(team: current_team)
    membership&.role
  end

  def can_manage_team?
    %w[owner admin].include?(current_user_role)
  end

  def can_edit_team_settings?
    current_user_role == "owner"
  end

  # Team-scoped resource helpers
  def scope_to_current_team(relation)
    return relation unless current_team
    relation.where(team: current_team)
  end

  def build_for_current_team(model_class, attributes = {})
    return model_class.new(attributes) unless current_team
    current_team.send(model_class.name.tableize).build(attributes)
  end

  def team_scoped_url_for(options = {})
    return url_for(options) unless current_team

    if options.is_a?(Hash)
      options = options.merge(team_id: current_team.id)
    end

    url_for(options)
  end

  # Breadcrumb support
  def team_breadcrumb_items
    return [] unless current_team

    [
      { name: t("navigation.teams"), path: teams_path },
      { name: current_team.name, path: team_path(current_team) }
    ]
  end

  # For Pundit integration
  def pundit_user
    UserContext.new(current_user, current_team)
  end

  private

  def require_team
    unless current_team
      redirect_to teams_path,
                  alert: t("teams.errors.no_team_selected")
    end
  end
end
