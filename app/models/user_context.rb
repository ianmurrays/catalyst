# frozen_string_literal: true

# UserContext struct for passing both user and team context to Pundit policies
UserContext = Struct.new(:user, :team) do
  # Get the user's role in the current team
  # @return [String, nil] the user's role in the team (owner, admin, member, viewer) or nil if no membership
  def team_role
    return nil unless user && team

    user.memberships.find_by(team: team)&.role
  end

  # Check if user has any role in the current team
  # @return [Boolean] true if user is a member of the team
  def team_member?
    team_role.present?
  end

  # Check if user is an owner of the current team
  # @return [Boolean] true if user is an owner
  def team_owner?
    team_role == "owner"
  end

  # Check if user is an admin of the current team
  # @return [Boolean] true if user is an admin
  def team_admin?
    team_role == "admin"
  end

  # Check if user has admin privileges (owner or admin)
  # @return [Boolean] true if user is owner or admin
  def team_admin_or_owner?
    %w[owner admin].include?(team_role)
  end
end
