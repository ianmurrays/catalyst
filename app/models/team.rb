class Team < ApplicationRecord
  # Audit all changes except timestamps
  audited except: [ :created_at, :updated_at ]

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :invitations, dependent: :destroy

  # Role-specific associations
  has_many :owners, -> { where(memberships: { role: :owner }) }, through: :memberships, source: :user
  has_many :admins, -> { where(memberships: { role: :admin }) }, through: :memberships, source: :user
  has_many :members, -> { where(memberships: { role: :member }) }, through: :memberships, source: :user

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, uniqueness: { conditions: -> { where(deleted_at: nil) } }

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Callbacks
  before_validation :generate_slug, if: :slug_needs_generation?

  # Use slug for URLs
  def to_param
    slug
  end

  # Soft deletion
  def destroy
    update(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def restore
    update(deleted_at: nil)
  end

  # Member checking methods
  def has_member?(user)
    return false unless user
    memberships.exists?(user: user)
  end

  def member_role(user)
    return nil unless user
    memberships.find_by(user: user)&.role
  end

  def owner?(user)
    return false unless user
    memberships.exists?(user: user, role: :owner)
  end

  def admin?(user)
    return false unless user
    memberships.exists?(user: user, role: [ :owner, :admin ])
  end

  def member?(user)
    return false unless user
    memberships.exists?(user: user, role: [ :owner, :admin, :member ])
  end

  def viewer?(user)
    return false unless user
    memberships.exists?(user: user, role: :viewer)
  end

  private

  def slug_needs_generation?
    slug.blank? && name.present?
  end

  def generate_slug
    return if name.blank?

    base_slug = name.downcase
                   .gsub(/[^a-z0-9\s\-]/, "") # Remove special characters
                   .gsub(/\s+/, "-")          # Replace spaces with hyphens
                   .gsub(/-+/, "-")           # Replace multiple hyphens with single
                   .strip
                   .chomp("-")                # Remove trailing hyphens

    candidate_slug = base_slug
    counter = 0

    while Team.unscoped.where(slug: candidate_slug, deleted_at: nil).exists?
      counter += 1
      candidate_slug = "#{base_slug}-#{counter}"
    end

    self.slug = candidate_slug
  end
end
