# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  # index?: logged in users can see their teams
  def index?
    logged_in?
  end

  # show?: team members can view
  def show?
    logged_in? && record.has_member?(user)
  end

  # create?: check Rails.configuration.allow_team_creation
  def create?
    return false unless logged_in?

    Rails.configuration.respond_to?(:allow_team_creation) ?
      Rails.configuration.allow_team_creation :
      true # default to true if configuration not set
  end

  # update?: owners and admins only
  def update?
    logged_in? && (record.admin?(user) || record.owner?(user))
  end

  # destroy?: owners only
  def destroy?
    logged_in? && record.owner?(user)
  end

  # switch?: team members only
  def switch?
    logged_in? && record.has_member?(user)
  end

  # restore?: owners only (for soft-deleted teams)
  def restore?
    logged_in? && record.owner?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless logged_in?

      # Return teams where user is a member
      scope.joins(:memberships)
           .where(memberships: { user: user })
           .distinct
    end
  end
end
