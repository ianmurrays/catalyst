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

  # Custom preferences assignment to handle nested attributes elegantly
  def preferences=(attributes)
    if attributes.is_a?(Hash)
      # Get current preferences or create new instance
      current_prefs = self.preferences || UserPreferences.new

      # Use standard Rails assignment - store_model handles everything
      current_prefs.assign_attributes(attributes)

      # Assign the updated preferences object
      super(current_prefs)
    else
      # Handle direct UserPreferences object assignment or other types
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
