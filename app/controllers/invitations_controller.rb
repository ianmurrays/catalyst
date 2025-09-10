# frozen_string_literal: true

class InvitationsController < ApplicationController
  include Secured

  before_action :set_team, only: [ :index, :new, :create, :destroy ]
  before_action :set_invitation, only: [ :destroy ]
  skip_before_action :require_authentication, only: [ :accept ]

  # Use team context for Pundit on team-scoped actions
  def pundit_user
    UserContext.new(current_user, @team || @invitation&.team)
  end

  def index
    authorize Invitation
    @status = params[:status].to_s
    @invitations = policy_scope(@team.invitations).order(created_at: :desc)
    @invitations = case @status
    when "used" then @invitations.used
    when "active" then @invitations.active
    else @invitations.active
    end

    render Views::Invitations::Index.new(team: @team, invitations: @invitations, status: @status)
  end

  def new
    authorize Invitation
    @invitation = @team.invitations.new(role: :member)

    render Views::Invitations::New.new(team: @team, invitation: @invitation)
  end

  def create
    authorize Invitation

    role = invitation_params[:role]
    expires_in = parse_expires_in(invitation_params[:expires_in])

    begin
      invitation, raw_token = Teams::InvitationService.create(
        team: @team,
        role: role,
        created_by: current_user,
        expires_in: expires_in
      )

      generated_url = accept_invitation_url(token: raw_token)

      flash[:notice] = t("invitations.flash.created")
      render Views::Invitations::New.new(team: @team, invitation: invitation, generated_url: generated_url), status: :created
    rescue Teams::InvitationService::RoleNotPermitted => e
      @invitation = @team.invitations.new(role: role)
      flash.now[:alert] = e.message
      render Views::Invitations::New.new(team: @team, invitation: @invitation), status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      @invitation = e.record
      render Views::Invitations::New.new(team: @team, invitation: @invitation), status: :unprocessable_content
    end
  end

  # Public endpoint accessed via /invitations/:token
  def accept
    token = params[:token].to_s

    unless logged_in?
      session[:invitation_token] = token
      session[:return_to] = request.fullpath
      redirect_to login_path
      return
    end

    # Find invitation by token digest for authorization context
    token_digest = Teams::InvitationService.digest(token)
    invitation = Invitation.find_by!(token: token_digest)
    @team = invitation.team

    # Handle unusable tokens BEFORE authorization to provide precise feedback
    if invitation.expired?
      flash[:alert] = t("invitations.flash.expired")
      return redirect_to root_path
    end

    if invitation.used?
      flash[:alert] = t("invitations.flash.already_used")
      return redirect_to root_path
    end

    if @team.has_member?(current_user)
      flash[:notice] = t("invitations.flash.already_member")
      return redirect_to team_path(@team)
    end

    authorize invitation, :accept?

    Teams::InvitationService.accept(token: token, user: current_user)

    flash[:notice] = t("invitations.flash.accepted")
    render Views::Invitations::Accept.new(team: @team)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t("pundit.not_authorized")
    redirect_to root_path
  end

  def destroy
    authorize @invitation

    if @invitation.used?
      flash[:alert] = t("invitations.flash.already_used", default: "This invitation link has already been used.")
    else
      @invitation.destroy!
      flash[:notice] = t("invitations.flash.revoked", default: "Invitation revoked.")
    end

    redirect_to team_invitations_path(@team)
  end

  private

  def set_team
    @team = Team.active.find_by!(slug: params[:team_id])
  end

  def set_invitation
    set_team
    @invitation = @team.invitations.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:role, :expires_in)
  end

  # Map UI values to durations:
  # "1h" => 1.hour, "1d" => 1.day, "3d" => 3.days, "1w" => 1.week, "never" => nil
  def parse_expires_in(value)
    case value.to_s
    when "1h" then 1.hour
    when "1d" then 1.day
    when "3d" then 3.days
    when "1w" then 1.week
    when "never", "" then nil
    else
      nil
    end
  end
end
