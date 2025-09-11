# frozen_string_literal: true

class Components::Teams::TeamSwitcher < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(current_team: nil, available_teams: [], show_role_badges: true, mobile: false, size: :default)
    @current_team = current_team
    @available_teams = available_teams
    @show_role_badges = show_role_badges
    @mobile = mobile
    @size = size
  end

  def view_template
    return render_no_teams if @available_teams.empty?
    return render_single_team if @available_teams.size == 1

    render_team_selector
  end

  private

  def render_team_selector
    form_with(
      url: switch_team_path(@current_team&.id || @available_teams.first.id),
      method: :post,
      local: true,
      class: form_classes,
      data: {
        controller: "teams--team-switcher",
        "teams--team-switcher-current-team-value": @current_team&.id,
        "teams--team-switcher-switch-url-value": "/teams/switch/:team_id",
        "teams--team-switcher-teams-mapping-value": teams_mapping_json,
        "teams--team-switcher-ruby-ui--select-item-outlet": ".item"
      }
    ) do |form|
      render RubyUI::Select::Select.new do
        render RubyUI::Select::SelectInput.new(
          name: "team_id",
          value: @current_team&.id,
          data: { "teams--team-switcher-target": "input" }
        )

        render_select_trigger
        render_select_content
      end
    end
  end

  def render_select_trigger
    render RubyUI::Select::SelectTrigger.new(
      class: trigger_classes,
      id: "team-switcher-trigger",
      data: {
        "teams--team-switcher-target": "trigger"
      }
    ) do
      div(class: "flex items-center gap-2") do
        render_team_avatar(@current_team) if @current_team
        render RubyUI::Select::SelectValue.new(
          placeholder: t("teams.select_team")
        ) do
          span(data: { "teams--team-switcher-target": "currentTeamName" }) do
            @current_team ? team_display_name(@current_team) : t("teams.no_team")
          end
        end
        render_loading_spinner
        render_dropdown_icon
      end
    end
  end

  def render_select_content
    render RubyUI::Select::SelectContent.new(
      class: content_classes
    ) do
      @available_teams.each do |team|
        render_team_option(team)
      end
    end
  end

  def render_team_option(team)
    render RubyUI::Select::SelectItem.new(
      value: team.id.to_s,
      class: merge_classes([
        "flex items-center justify-between py-2",
        ("bg-muted" if team == @current_team)
      ]),
      data: { "team-name": team.name }
    ) do
      div(class: "flex items-center gap-2 flex-1") do
        render_team_avatar(team)

        div(class: "flex flex-col") do
          span(class: "font-medium text-sm") { team.name }
          if @show_role_badges
            render_role_badge(team)
          end
        end
      end

      if team == @current_team
        render_current_indicator
      end
    end
  end

  def render_team_avatar(team)
    div(class: "flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-xs font-medium") do
      team.name.first.upcase
    end
  end

  def render_role_badge(team)
    role = user_role_for_team(team)
    return unless role

    render RubyUI::Badge::Badge.new(
      variant: badge_variant_for_role(role),
      class: "text-xs"
    ) do
      t("teams.roles.#{role}")
    end
  end

  def render_current_indicator
    div(class: "text-primary") do
      svg(class: "h-4 w-4", viewBox: "0 0 24 24", fill: "currentColor") do |s|
        s.path(d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z")
      end
    end
  end

  def render_loading_spinner
    div(
      class: "hidden animate-spin",
      data: { "teams--team-switcher-target": "loading" }
    ) do
      svg(
        class: "h-4 w-4",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        "stroke-width": "2"
      ) do |s|
        s.circle(cx: "12", cy: "12", r: "10")
        s.path(d: "m12 2v8l3-3 3 3")
      end
    end
  end

  def render_dropdown_icon
    svg(
      class: "h-4 w-4 opacity-50",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2"
    ) do |s|
      s.polyline(points: "6,9 12,15 18,9")
    end
  end

  def render_no_teams
    div(class: "text-sm text-muted-foreground") do
      t("teams.no_teams_available")
    end
  end

  def render_single_team
    div(class: "flex items-center gap-2") do
      render_team_avatar(@available_teams.first)
      span(class: "text-sm font-medium") do
        team_display_name(@available_teams.first)
      end
      if @show_role_badges
        render_role_badge(@available_teams.first)
      end
    end
  end

  # Helper methods
  def team_display_name(team)
    if @mobile && team.name.length > 15
      "#{team.name[0..12]}..."
    else
      team.name
    end
  end

  def user_role_for_team(team)
    # This will need to be passed in or accessed via helper
    current_user&.membership_for(team)&.role
  end

  def badge_variant_for_role(role)
    case role
    when "owner"
      :default
    when "admin"
      :secondary
    else
      :outline
    end
  end

  def form_classes
    merge_classes([
      "team-switcher-form",
      (@mobile ? "w-full" : "w-auto")
    ])
  end

  def trigger_classes
    merge_classes([
      "justify-start gap-2",
      size_classes,
      (@mobile ? "w-full" : "min-w-[200px]")
    ])
  end

  def content_classes
    merge_classes([
      "w-[var(--radix-select-trigger-width)] min-w-[200px]",
      (@mobile ? "max-h-[300px]" : "max-h-[400px]")
    ])
  end

  def size_classes
    case @size
    when :sm
      "h-8 text-sm"
    when :lg
      "h-12 text-base"
    else
      "h-10 text-sm"
    end
  end

  # Simple class merging helper
  def merge_classes(class_list)
    class_list.compact.join(" ")
  end

  # Generate JSON mapping of team IDs to names for JavaScript
  def teams_mapping_json
    mapping = @available_teams.each_with_object({}) do |team, hash|
      hash[team.id.to_s] = team.name
    end
    mapping.to_json
  end
end
