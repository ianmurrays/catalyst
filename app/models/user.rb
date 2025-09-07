class User < ApplicationRecord
  # Define preferences attribute with UserPreferences embedded model
  attribute :preferences, UserPreferences.to_type,
            default: -> { UserPreferences.new }

  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :preferences, store_model: true

  # Delegate preference methods to embedded model for backward compatibility
  delegate :language=, :timezone, :timezone=, :timezone_object, to: :preferences

  # Custom language method to handle defaults
  def language
    preferences&.language || "en"
  end

  # Custom preferences assignment to handle nested attributes
  def preferences=(attributes)
    if attributes.is_a?(Hash)
      # Handle nested hash assignment for store_model
      current_prefs = self.preferences || UserPreferences.new

      # Update language if provided
      current_prefs.language = attributes[:language] || attributes["language"] if attributes.key?(:language) || attributes.key?("language")

      # Update timezone if provided
      if attributes.key?(:timezone) || attributes.key?("timezone")
        timezone_value = attributes[:timezone] || attributes["timezone"]
        # Convert empty string to default UTC
        current_prefs.timezone = timezone_value.present? ? timezone_value : "UTC"
      end

      # Update email notifications if provided
      if attributes.key?(:email_notifications) || attributes.key?("email_notifications")
        email_attrs = attributes[:email_notifications] || attributes["email_notifications"]
        if email_attrs.is_a?(Hash)
          current_prefs.email_notifications.profile_updates = email_attrs[:profile_updates] || email_attrs["profile_updates"] if email_attrs.key?(:profile_updates) || email_attrs.key?("profile_updates")
          current_prefs.email_notifications.security_alerts = email_attrs[:security_alerts] || email_attrs["security_alerts"] if email_attrs.key?(:security_alerts) || email_attrs.key?("security_alerts")
          current_prefs.email_notifications.feature_announcements = email_attrs[:feature_announcements] || email_attrs["feature_announcements"] if email_attrs.key?(:feature_announcements) || email_attrs.key?("feature_announcements")
        end
      end

      super(current_prefs)
    else
      super
    end
  end

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
      preferences: UserPreferences.new
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

  # Keep available_languages for backward compatibility
  def available_languages
    LocaleService.language_options
  end

  private

  def auth_provider_user_info
    @auth_provider_user_info ||= fetch_auth_provider_user_info
  end

  def fetch_auth_provider_user_info
    return nil unless auth0_sub

    Rails.cache.fetch("auth_provider_user_#{auth0_sub}", expires_in: 1.hour) do
      {}
    end
  end
end
