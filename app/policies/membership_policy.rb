# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  # index?: team members can see member list
  def index?
    team_member?
  end

  # show?: team members can see individual memberships
  def show?
    team_member?
  end

  # create?: owners and admins can invite (create memberships)
  def create?
    team_admin_or_owner?
  end

  # update?: owners and admins can change roles (with restrictions)
  def update?
    return false unless team_admin_or_owner?

    # Additional restrictions for role changes
    if changing_role?
      # Can't demote the last owner
      return false if demoting_last_owner?

      # Users can't demote themselves from owner role
      return false if self_demoting_from_owner?
    end

    true
  end

  # destroy?: owners and admins can remove members (with restrictions)
  def destroy?
    return false unless team_admin_or_owner?

    # Can't remove the last owner
    return false if removing_last_owner?

    # Users can't remove themselves if they are the last owner
    return false if self_removing_as_last_owner?

    true
  end

  private

  # Check if the operation is changing a role
  def changing_role?
    record.role_changed? if record.persisted?
  end

  # Check if this would demote the last owner
  def demoting_last_owner?
    return false unless record.role_was == "owner" && record.role != "owner"

    # Count other owners in the team
    other_owners = record.team.memberships.where(role: "owner").where.not(id: record.id).count
    other_owners == 0
  end

  # Check if user is demoting themselves from owner
  def self_demoting_from_owner?
    record.user == user && record.role_was == "owner" && record.role != "owner"
  end

  # Check if this would remove the last owner
  def removing_last_owner?
    return false unless record.role == "owner"

    # Count other owners in the team
    other_owners = record.team.memberships.where(role: "owner").where.not(id: record.id).count
    other_owners == 0
  end

  # Check if user is removing themselves as the last owner
  def self_removing_as_last_owner?
    record.user == user && removing_last_owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless logged_in?

      # If no team context, return memberships for all teams where user is a member
      if team.nil?
        user_team_ids = user.memberships.select(:team_id)
        return scope.where(team_id: user_team_ids)
      end

      # With team context, return memberships for that team if user is a member
      return scope.none unless user.memberships.exists?(team: team)

      scope.where(team: team)
    end
  end
end
