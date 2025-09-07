# frozen_string_literal: true

class UserPreferences
  include StoreModel::Model

  # Language preference
  attribute :language, :string

  # Timezone preference
  attribute :timezone, :string, default: "UTC"

  # Nested email notifications
  attribute :email_notifications, EmailNotificationPreferences.to_type,
            default: -> { EmailNotificationPreferences.new }

  # Validations
  validates :language, inclusion: {
    in: -> { LocaleService.available_locales.map(&:to_s) }
  }, allow_nil: true
  validates :timezone, inclusion: {
    in: -> { ActiveSupport::TimeZone.all.map(&:name) }
  }
  validates :email_notifications, store_model: true

  # Helper methods (maintain existing API)
  def timezone_object
    ActiveSupport::TimeZone[timezone]
  end
end
