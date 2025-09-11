# frozen_string_literal: true

class OnboardingController < ApplicationController
  include AuthProvider
  include Secured
  skip_before_action :set_current_team

  def show
    # Check if user already has teams
    if current_user.teams.any?
      redirect_to teams_path
      return
    end

    # Check configuration
    @can_create_teams = Rails.configuration.allow_team_creation
    render Views::Onboarding::Show.new(can_create_teams: @can_create_teams)
  end

  def create_team
    # Handle team creation from onboarding
    unless Rails.configuration.allow_team_creation
      redirect_to onboarding_path, alert: t("onboarding.team_creation_disabled")
      return
    end

    @team = Team.new(team_params)

    begin
      Team.transaction do
        @team.save!
        # Make current user the owner
        @team.memberships.create!(user: current_user, role: :owner)
      end

      redirect_to team_path(@team), notice: t("onboarding.flash.team_created")
    rescue ActiveRecord::RecordInvalid
      @can_create_teams = Rails.configuration.allow_team_creation
      render Views::Onboarding::Show.new(can_create_teams: @can_create_teams, team: @team), status: :unprocessable_content
    end
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
