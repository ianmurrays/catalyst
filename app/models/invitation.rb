class Invitation < ApplicationRecord
  # Custom exceptions
  class InvitationExpired < StandardError; end
  class InvitationAlreadyUsed < StandardError; end
  class UserAlreadyMember < StandardError; end

  # Associations
  belongs_to :team
  belongs_to :created_by, class_name: "User"
  belongs_to :used_by, class_name: "User", optional: true

  # Role enum
  enum :role, { owner: 0, admin: 1, member: 2, viewer: 3 }

  # Validations
  validates :team, presence: true
  validates :token, uniqueness: true
  validates :role, presence: true
  validates :created_by, presence: true

  # Scopes
  scope :active, -> { where(used_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where(used_at: nil).where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :used, -> { where.not(used_at: nil) }
  scope :by_team, ->(team) { where(team: team) }

  # Callbacks
  before_validation :generate_token, if: :token_needs_generation?

  # Class methods
  def self.expiration_options
    [
      [ "1 hour", 1.hour ],
      [ "1 day", 1.day ],
      [ "3 days", 3.days ],
      [ "1 week", 1.week ],
      [ "Never", nil ]
    ]
  end

  # Expiration methods
  def expired?
    return false if expires_at.nil?
    expires_at <= Time.current
  end

  def expires_in
    return nil if expires_at.nil?
    expires_at - Time.current
  end

  def set_expiration(duration)
    self.expires_at = duration ? duration.from_now : nil
  end

  # Status methods
  def used?
    used_at.present?
  end

  def usable?
    !used? && !expired?
  end

  # Acceptance flow
  def accept!(user)
    raise InvitationExpired if expired?
    raise InvitationAlreadyUsed if used?
    raise UserAlreadyMember if team.has_member?(user)

    transaction do
      membership = team.memberships.create!(
        user: user,
        role: role
      )

      update!(
        used_at: Time.current,
        used_by: user
      )

      membership
    end
  end

  # Delegation methods
  def team_name
    team&.name
  end

  def creator_name
    created_by&.name
  end

  private

  def token_needs_generation?
    token.blank?
  end

  def generate_token
    loop do
      candidate_token = SecureRandom.urlsafe_base64(32)
      unless self.class.exists?(token: candidate_token)
        self.token = candidate_token
        break
      end
    end
  end
end
