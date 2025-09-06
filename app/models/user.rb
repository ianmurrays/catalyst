class User < ApplicationRecord
  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email_source, inclusion: { in: %w[auth_provider manual] }

  validate :prevent_auth_provider_email_modification, on: :update

  def self.find_or_create_from_auth_provider(auth_provider_user_info)
    auth0_sub = auth_provider_user_info["sub"]
    user = find_by(auth0_sub: auth0_sub)

    return user if user

    # Try to get email from authentication provider response (may be nil for GitHub users)
    auth_provider_email = auth_provider_user_info.dig("email")

    create!(
      auth0_sub: auth0_sub,
      display_name: auth_provider_user_info["name"],
      email: auth_provider_email,
      email_source: auth_provider_email.present? ? "auth_provider" : "manual",
      preferences: default_preferences
    )
  end

  def email_address
    email
  end

  def name
    display_name.presence || auth_provider_user_info&.dig("name") || "Unknown User"
  end

  def picture_url
    @picture_url ||= auth_provider_user_info["picture"] if auth_provider_user_info
  end

  def auth_provider_email?
    email_source == "auth_provider"
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

  def auth_provider_user_info
    @auth_provider_user_info ||= fetch_auth_provider_user_info
  end

  def fetch_auth_provider_user_info
    return nil unless auth0_sub

    Rails.cache.fetch("auth_provider_user_#{auth0_sub}", expires_in: 1.hour) do
      {}
    end
  end

  def prevent_auth_provider_email_modification
    return unless auth_provider_email? && email_changed?

    errors.add(:email, "cannot be modified as it is provided by your authentication provider")
  end
end
