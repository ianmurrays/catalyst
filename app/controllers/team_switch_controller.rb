class TeamSwitchController < ApplicationController
  include Secured

  def update
    # Find the team by id, then authorize membership via policy.
    # This ensures non-members trigger Pundit::NotAuthorizedError (handled globally),
    # instead of raising ActiveRecord::RecordNotFound.
    team = Team.find(params[:team_id])
    authorize team, :switch?

    # Update session and persistent cookie using consistent method
    session[:current_team_id] = team.id
    store_team_preference(team)

    # Clear any cached Pundit user context per Pundit docs
    pundit_reset!

    redirect_to after_switch_path(team)
  end

  private

  def after_switch_path(team)
    request.referrer || team_path(team)
  end
end
