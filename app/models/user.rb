class User < ApplicationRecord
  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true

  def self.find_or_create_from_auth0(auth0_user_info)
    auth0_sub = auth0_user_info["sub"]
    user = find_by(auth0_sub: auth0_sub)

    return user if user

    create!(
      auth0_sub: auth0_sub,
      display_name: auth0_user_info["name"],
      preferences: default_preferences
    )
  end

  def email
    @email ||= auth0_user_info["email"] if auth0_user_info
  end

  def name
    display_name.presence || auth0_user_info&.dig("name") || "Unknown User"
  end

  def picture_url
    @picture_url ||= auth0_user_info["picture"] if auth0_user_info
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
end
