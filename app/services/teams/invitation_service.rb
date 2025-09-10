# frozen_string_literal: true

module Teams
  class InvitationService
    class RoleNotPermitted < StandardError; end

    # Create an invitation with a hashed token.
    # Returns [invitation, raw_token] (controller should build the full URL)
    #
    # @param team [Team]
    # @param role [String, Symbol] one of: owner, admin, member, viewer
    # @param created_by [User]
    # @param expires_in [ActiveSupport::Duration, nil] if nil, never expires
    def self.create(team:, role:, created_by:, expires_in: nil)
      raise ArgumentError, "team required" unless team
      raise ArgumentError, "created_by required" unless created_by
      role = role.to_s

      # Permission checks: creator can't invite with higher privileges than themselves
      ensure_role_permitted!(team:, creator: created_by, target_role: role)

      raw_token = nil
      token_digest = nil

      # Generate a unique token digest
      loop do
        raw_token = SecureRandom.urlsafe_base64(32)
        token_digest = digest(raw_token)
        break unless Invitation.exists?(token: token_digest)
      end

      invitation = Invitation.new(
        team: team,
        token: token_digest,
        role: role,
        created_by: created_by
      )

      # Expiration handling
      if expires_in.present?
        invitation.expires_at = expires_in.from_now
      else
        invitation.expires_at = nil # never expires
      end

      invitation.save!

      # TODO: Rate limiting & audit trail can be implemented here (Phase 4 scope: log only)
      Rails.logger.info("[InvitationService] Invitation created team_id=#{team.id} by_user_id=#{created_by.id} role=#{role} expires_at=#{invitation.expires_at}")

      [ invitation, raw_token ]
    end

    # Accept an invitation identified by raw token for a given user.
    # Returns the created Membership.
    #
    # @param token [String] raw (unhashed) token from the URL
    # @param user [User]
    def self.accept(token:, user:)
      raise ArgumentError, "token required" if token.blank?
      raise ArgumentError, "user required" unless user

      token_digest = digest(token)
      invitation = Invitation.find_by!(token: token_digest)

      membership = invitation.accept!(user)

      Rails.logger.info("[InvitationService] Invitation accepted invitation_id=#{invitation.id} used_by_id=#{user.id}")

      membership
    end

    # Compute a SHA256 hex digest suitable for storage in invitations.token
    def self.digest(raw_token)
      OpenSSL::Digest::SHA256.hexdigest(raw_token)
    end

    # Validate the creator is allowed to invite at target_role
    # - Owner can invite any role
    # - Admin cannot invite owner
    # - Members/viewers cannot create invitations (policy should prevent this, but guard here)
    def self.ensure_role_permitted!(team:, creator:, target_role:)
      creator_role = team.member_role(creator) # returns string or nil
      # If no role in team, not permitted
      raise RoleNotPermitted, "Creator is not a member of this team" if creator_role.blank?

      # Map roles to rank: lower number = higher privilege (from enums)
      ranks = Invitation.roles # { "owner" => 0, "admin" => 1, "member" => 2, "viewer" => 3 }
      creator_rank = ranks[creator_role.to_s]
      target_rank  = ranks[target_role.to_s]

      raise RoleNotPermitted, "Invalid target role" if target_rank.nil? || creator_rank.nil?

      # Disallow inviting a higher-privileged role (lower rank number)
      if target_rank < creator_rank
        raise RoleNotPermitted, "Cannot invite a role higher than your own"
      end

      # Additionally, members/viewers should not be able to invite anyone
      if creator_role.to_s.in?(%w[member viewer])
        raise RoleNotPermitted, "Insufficient permissions to invite"
      end

      true
    end
  end
end
