module TeamsHelper
  def current_team_name
    current_team&.name || t("teams.no_team")
  end

  def user_teams_for_select
    return [] unless current_user

    current_user.teams.map { |t| [ t.name, t.id ] }
  end

  def team_role_badge(team)
    return nil unless current_user && team

    current_user.memberships.find_by(team: team)&.role
  end
end
