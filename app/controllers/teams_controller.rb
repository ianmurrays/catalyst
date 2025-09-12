class TeamsController < ApplicationController
  include Secured # Requires authentication for all actions

  before_action :set_team, only: [ :show, :edit, :update, :destroy, :restore ]

  def index
    @teams = policy_scope(Team.active)
    render Views::Teams::Index.new(teams: @teams)
  end

  def show
    authorize @team
    render Views::Teams::Show.new(team: @team)
  end

  def new
    @team = Team.new

    # Check configuration before authorization
    unless Rails.configuration.respond_to?(:allow_team_creation) && Rails.configuration.allow_team_creation
      flash[:alert] = t("teams.flash.creation_disabled")
      redirect_to teams_path and return
    end

    authorize @team
    render Views::Teams::New.new(team: @team)
  end

  def create
    @team = Team.new(team_params)

    # Check configuration before authorization
    unless Rails.configuration.respond_to?(:allow_team_creation) && Rails.configuration.allow_team_creation
      flash[:alert] = t("teams.flash.creation_disabled")
      redirect_to teams_path and return
    end

    authorize @team

    if @team.save
      # Add the creator as the owner
      @team.memberships.create!(user: current_user, role: :owner)

      flash[:notice] = t("teams.flash.created")
      redirect_to team_path(@team)
    else
      render Views::Teams::New.new(team: @team), status: :unprocessable_content
    end
  end

  def edit
    authorize @team
    render Views::Teams::Edit.new(team: @team)
  end

  def update
    authorize @team

    if @team.update(team_params)
      flash[:notice] = t("teams.flash.updated")
      redirect_to team_path(@team)
    else
      render Views::Teams::Edit.new(team: @team), status: :unprocessable_content
    end
  end

  def destroy
    authorize @team

    @team.destroy
    flash[:notice] = t("teams.flash.deleted")
    redirect_to teams_path
  end

  def restore
    authorize @team

    @team.restore
    flash[:notice] = t("teams.flash.restored")
    redirect_to team_path(@team)
  end

  private

  def set_team
    # Find team by slug, including soft-deleted teams for restore action
    if action_name == "restore"
      @team = Team.unscoped.find_by!(slug: params[:id])
    else
      @team = Team.active.find_by!(slug: params[:id])
    end
  end

  def team_params
    params.require(:team).permit(:name)
  end
end
