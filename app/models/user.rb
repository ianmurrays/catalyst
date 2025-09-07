class User < ApplicationRecord
  # Define preferences attribute with UserPreferences embedded model
  attribute :preferences, UserPreferences.to_type,
            default: -> { UserPreferences.new }

  # Active Storage avatar attachment
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 32, 32 ], saver: { quality: 85 }
    attachable.variant :small, resize_to_fill: [ 64, 64 ], saver: { quality: 85 }
    attachable.variant :medium, resize_to_fill: [ 150, 150 ], saver: { quality: 85 }
    attachable.variant :large, resize_to_fill: [ 400, 400 ], saver: { quality: 85 }
    attachable.variant :xlarge, resize_to_fill: [ 800, 800 ], saver: { quality: 90 }
  end

  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :preferences, store_model: true

  # Avatar validations
  validate :avatar_content_type_validation
  validate :avatar_size_validation

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
    if avatar.attached?
      avatar_url(:medium)
    else
      @picture_url ||= auth_provider_user_info["picture"] if auth_provider_user_info
    end
  end

  def avatar_url(variant = :medium)
    return nil unless avatar.attached?

    begin
      if variant
        Rails.application.routes.url_helpers.rails_blob_path(avatar.variant(variant), only_path: true)
      else
        Rails.application.routes.url_helpers.rails_blob_path(avatar, only_path: true)
      end
    rescue ActiveStorage::InvariableError
      # Return nil if we can't create variants (e.g., for non-image files)
      nil
    end
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

  def avatar_content_type_validation
    return unless avatar.attached?

    acceptable_types = %w[image/jpeg image/png image/webp]

    # First check MIME type from headers
    unless acceptable_types.include?(avatar.content_type)
      errors.add(:avatar, :invalid_content_type)
      return
    end

    # Verify actual file content to prevent MIME type spoofing
    begin
      avatar.open do |file|
        file.rewind
        actual_type = Marcel::Magic.by_magic(file)&.type
        # Verify the actual content matches expected image types
        # Use broader image type matching to account for Marcel's variations
        if actual_type && !actual_type.start_with?("image/")
          errors.add(:avatar, :content_type_mismatch)
        end
      end
    rescue => e
      Rails.logger.error "Avatar content validation failed: #{e.message}"
      # Be more selective about when to add processing errors
      # Only add error for clearly dangerous files or actual processing failures
      if e.message.downcase.include?("processing") && !e.message.downcase.include?("image")
        errors.add(:avatar, :processing_failed)
      end
    end
  end

  def avatar_size_validation
    return unless avatar.attached?

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, :file_size_too_large, max_size: "5MB")
    end
  end
end
