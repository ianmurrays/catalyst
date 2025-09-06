class User < ApplicationRecord
  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email_source, inclusion: { in: %w[auth0 manual] }

  validate :prevent_auth0_email_modification, on: :update

  def self.find_or_create_from_auth0(auth0_user_info)
    auth0_sub = auth0_user_info["sub"]
    user = find_by(auth0_sub: auth0_sub)

    return user if user

    # Try to get email from Auth0 response (may be nil for GitHub users)
    auth0_email = auth0_user_info.dig("email")

    create!(
      auth0_sub: auth0_sub,
      display_name: auth0_user_info["name"],
      email: auth0_email,
      email_source: auth0_email.present? ? "auth0" : "manual",
      preferences: default_preferences
    )
  end

  def email_address
    email
  end

  def name
    display_name.presence || auth0_user_info&.dig("name") || "Unknown User"
  end

  def picture_url
    @picture_url ||= auth0_user_info["picture"] if auth0_user_info
  end

  def auth0_email?
    email_source == "auth0"
  end

  def manual_email?
    email_source == "manual"
  end

  private

  def self.default_preferences
    {
      email_notifications: {
        profile_updates: true,
        security_alerts: true,
        feature_announcements: false
      },
      timezone: "UTC",
      language: "en"
    }
  end

  def auth0_user_info
    @auth0_user_info ||= fetch_auth0_user_info
  end

  def fetch_auth0_user_info
    return nil unless auth0_sub

    Rails.cache.fetch("auth0_user_#{auth0_sub}", expires_in: 1.hour) do
      {}
    end
  end

  def prevent_auth0_email_modification
    return unless auth0_email? && email_changed?

    errors.add(:email, "cannot be modified as it is provided by Auth0")
  end
end
