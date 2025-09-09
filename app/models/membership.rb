class Membership < ApplicationRecord
  # Audit all changes except timestamps
  audited except: [ :created_at, :updated_at ]

  # Associations
  belongs_to :user
  belongs_to :team

  # Role enum
  enum :role, { owner: 0, admin: 1, member: 2, viewer: 3 }

  # Validations
  validates :user, presence: true
  validates :team, presence: true
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :team_id, message: "has already been taken" }

  # Scopes
  scope :active, -> { joins(:team).merge(Team.active) }
  scope :by_role, ->(role) { where(role: role) }

  # Role hierarchy methods
  def admin_or_above?
    owner? || admin?
  end

  def member_or_above?
    owner? || admin? || member?
  end

  # Delegation methods for convenience
  def user_name
    user&.name
  end

  def user_email
    user&.email
  end

  def team_name
    team&.name
  end
end
