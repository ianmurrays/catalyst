# frozen_string_literal: true

module PunditHelpers
  # Test that an action is permitted for the given user and record
  # @param action [Symbol] the action to test (e.g., :show?, :create?)
  # @param user [User] the user to test
  # @param record [Object] the record being accessed
  # @param team [Team, nil] the current team context (optional)
  def permit_action(action, user:, record:, team: nil)
    context = UserContext.new(user, team)
    policy = described_class.new(context, record)
    expect(policy.send("#{action}?")).to be true
  end

  # Test that an action is forbidden for the given user and record
  # @param action [Symbol] the action to test (e.g., :show?, :create?)
  # @param user [User] the user to test
  # @param record [Object] the record being accessed
  # @param team [Team, nil] the current team context (optional)
  def forbid_action(action, user:, record:, team: nil)
    context = UserContext.new(user, team)
    policy = described_class.new(context, record)
    expect(policy.send("#{action}?")).to be false
  end

  # Create a user context for testing
  # @param user [User] the user
  # @param team [Team, nil] the team (optional)
  # @return [UserContext] the user context
  def user_context(user, team = nil)
    UserContext.new(user, team)
  end

  # Create a policy instance for testing
  # @param user [User] the user
  # @param record [Object] the record
  # @param team [Team, nil] the team context (optional)
  # @return [ApplicationPolicy] the policy instance
  def policy_for(user, record, team = nil)
    context = UserContext.new(user, team)
    described_class.new(context, record)
  end

  # Test a policy scope
  # @param user [User] the user
  # @param scope [ActiveRecord::Relation] the initial scope
  # @param team [Team, nil] the team context (optional)
  # @return [ActiveRecord::Relation] the resolved scope
  def policy_scope(user, scope, team = nil)
    context = UserContext.new(user, team)
    described_class::Scope.new(context, scope).resolve
  end

  # Create a membership for testing
  # @param user [User] the user
  # @param team [Team] the team
  # @param role [String] the role (owner, admin, member, viewer)
  # @return [Membership] the created membership
  def create_membership(user, team, role)
    create(:membership, user: user, team: team, role: role)
  end
end

RSpec.configure do |config|
  config.include PunditHelpers, type: :policy
end
