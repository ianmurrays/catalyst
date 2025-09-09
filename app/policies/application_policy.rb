# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user_context, :record

  def initialize(user_context, record)
    @user_context = user_context
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # Convenience method to access the user from user_context
  def user
    user_context&.user
  end

  # Convenience method to access the current team from user_context
  def team
    user_context&.team
  end

  # Check if user is logged in
  def logged_in?
    user.present?
  end

  # Check if user has any role in the current team
  def team_member?
    user_context&.team_member? || false
  end

  # Check if user is an owner of the current team
  def team_owner?
    user_context&.team_owner? || false
  end

  # Check if user is an admin of the current team
  def team_admin?
    user_context&.team_admin? || false
  end

  # Check if user has admin privileges (owner or admin)
  def team_admin_or_owner?
    user_context&.team_admin_or_owner? || false
  end

  # Get the user's role in the current team
  def team_role
    user_context&.team_role
  end

  class Scope
    def initialize(user_context, scope)
      @user_context = user_context
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user_context, :scope

    # Convenience method to access the user from user_context
    def user
      user_context&.user
    end

    # Convenience method to access the current team from user_context
    def team
      user_context&.team
    end

    # Check if user is logged in
    def logged_in?
      user.present?
    end
  end
end
