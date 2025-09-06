class User < ApplicationRecord
  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :language_must_be_available

  def self.find_or_create_from_auth_provider(auth_provider_user_info)
    auth0_sub = auth_provider_user_info["sub"]
    user = find_by(auth0_sub: auth0_sub)

    return user if user

    # Email is required from authentication provider
    auth_provider_email = auth_provider_user_info.dig("email")
    if auth_provider_email.blank?
      raise ArgumentError, "Email is required from authentication provider. Please ensure your social provider (GitHub, Google, etc.) is configured to provide email addresses by enabling the proper scopes."
    end

    create!(
      auth0_sub: auth0_sub,
      display_name: auth_provider_user_info["name"],
      email: auth_provider_email,
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

  # Language preference methods
  def available_languages
    LocaleService.language_options
  end

  def language
    preferences&.dig("language") || "en"
  end

  def language=(locale)
    self.preferences = {} if preferences.nil?
    self.preferences = preferences.merge("language" => locale)
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

  def language_must_be_available
    return if language.blank? || language == "en"

    available_locale_codes = LocaleService.available_locales.map(&:to_s)
    unless available_locale_codes.include?(language)
      errors.add(:language, "is not available")
    end
  end
end
