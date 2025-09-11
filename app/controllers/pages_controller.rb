# frozen_string_literal: true

class PagesController < ApplicationController
  def home
    # Home page is team-aware but doesn't require team context
    if logged_in?
      @user_teams = current_user.teams.includes(:memberships).limit(5)
      @team_stats = calculate_team_stats if current_team
    end

    render Views::PagesHome.new
  end

  private

  def calculate_team_stats
    return {} unless current_team

    {
      member_count: current_team.memberships.active.count,
      recent_activity: current_team.updated_at,
      user_role: current_user.memberships.find_by(team: current_team)&.role
    }
  end
end
