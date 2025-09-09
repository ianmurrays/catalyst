# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  # index?: owners and admins can see invitations
  def index?
    team_admin_or_owner?
  end

  # show?: owners and admins can see individual invitations
  def show?
    team_admin_or_owner?
  end

  # create?: owners and admins can create invitations
  def create?
    team_admin_or_owner?
  end

  # update?: owners and admins can update invitations
  def update?
    team_admin_or_owner?
  end

  # destroy?: invitation creator or team owners/admins can delete
  def destroy?
    return true if invitation_creator?
    return true if team_admin_or_owner?

    false
  end

  # accept?: any logged in user with valid token
  def accept?
    return false unless logged_in?
    return false unless record.usable?

    true
  end

  private

  # Check if current user created this invitation
  def invitation_creator?
    record.created_by == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless logged_in?

      # If no team context, return invitations created by user
      return scope.where(created_by: user) unless team

      # Return invitations for teams where user has admin privileges
      admin_team_ids = user.memberships
                           .where(role: %w[owner admin])
                           .select(:team_id)

      scope.where(team_id: admin_team_ids)
    end
  end
end
