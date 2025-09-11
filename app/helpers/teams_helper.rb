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

  # Essential helper methods for Phase 5 team switching

  def team_avatar(team, size: :default, css_class: nil)
    return fallback_avatar(size, css_class) unless team

    size_classes = avatar_size_classes(size)
    initial = team.name.first.upcase

    avatar_classes = merge_classes([
      "rounded-full bg-primary text-primary-foreground flex items-center justify-center font-medium",
      size_classes,
      css_class
    ])

    content_tag :div, class: avatar_classes do
      initial
    end
  end

  def current_user_role_in_team(team = current_team)
    return nil unless current_user && team

    current_user.memberships.find_by(team: team)&.role
  end

  def can_manage_team?(team = current_team)
    return false unless current_user && team

    role = current_user_role_in_team(team)
    %w[owner admin].include?(role)
  end

  def team_scoped_path(path, team = current_team)
    return path unless team

    if path.start_with?("/")
      "/teams/#{team.id}#{path}"
    else
      "/teams/#{team.id}/#{path}"
    end
  end

  def team_switcher_data_attributes
    {
      "controller" => "teams--team-switcher",
      "teams--team-switcher-current-team-value" => current_team&.id&.to_s,
      "teams--team-switcher-switch-url-value" => "/teams/switch/:team_id"
    }
  end

  private

  def avatar_size_classes(size)
    case size
    when :xs then "h-4 w-4 text-xs"
    when :sm then "h-6 w-6 text-xs"
    when :lg then "h-10 w-10 text-sm"
    when :xl then "h-12 w-12 text-base"
    else "h-8 w-8 text-sm" # default
    end
  end

  def fallback_avatar(size, css_class)
    size_classes = avatar_size_classes(size)

    avatar_classes = merge_classes([
      "rounded-full bg-gray-400 text-white flex items-center justify-center font-medium",
      size_classes,
      css_class
    ])

    content_tag :div, class: avatar_classes do
      "T"
    end
  end

  def merge_classes(classes)
    classes.compact.join(" ")
  end
end
