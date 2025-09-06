class User < ApplicationRecord
  validates :auth0_sub, presence: true, uniqueness: true
  validates :display_name, length: { in: 2..100 }, allow_blank: true
  validates :bio, length: { maximum: 500 }
  validates :phone, format: { with: /\A\+?[0-9\s\-\(\)]+\z/ }, allow_blank: true
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validates :company, length: { maximum: 100 }

  before_save :check_rate_limit
  after_save :update_profile_completion

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

  def profile_complete?
    required_fields = [ auth0_sub, display_name, bio, phone ]
    required_fields.all?(&:present?)
  end

  def profile_completion_percentage
    total_fields = [ auth0_sub, display_name, bio, phone, website, company ].size
    completed_fields = [ auth0_sub, display_name, bio, phone, website, company ].count(&:present?)
    ((completed_fields.to_f / total_fields) * 100).round
  end

  def can_update_profile?
    return true if updated_count == 0 || last_update_window.nil?
    return true if last_update_window < 1.hour.ago

    updated_count < 10
  end

  def updates_remaining
    return 10 if last_update_window.nil? || last_update_window < 1.hour.ago
    [ 10 - updated_count, 0 ].max
  end

  def next_reset_time
    return nil if last_update_window.nil?
    last_update_window + 1.hour
  end

  private

  def self.default_preferences
    {
      theme: "system",
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

  def check_rate_limit
    return unless will_save_change_to_any_profile_field?

    unless can_update_profile?
      errors.add(:base, "Profile update limit exceeded. Try again later.")
      throw(:abort)
    end

    reset_rate_limit_window if rate_limit_window_expired?
    increment_update_count
  end

  def will_save_change_to_any_profile_field?
    profile_fields = %w[display_name bio phone website company preferences]
    profile_fields.any? { |field| will_save_change_to_attribute?(field) }
  end

  def rate_limit_window_expired?
    last_update_window.nil? || last_update_window < 1.hour.ago
  end

  def reset_rate_limit_window
    self.updated_count = 0
    self.last_update_window = Time.current
  end

  def increment_update_count
    self.updated_count += 1
    self.last_update_window ||= Time.current
  end

  def update_profile_completion
    if profile_complete? && profile_completed_at.nil?
      update_column(:profile_completed_at, Time.current)
    elsif !profile_complete? && profile_completed_at.present?
      update_column(:profile_completed_at, nil)
    end
  end
end
