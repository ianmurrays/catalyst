# frozen_string_literal: true

class EmailNotificationPreferences
  include StoreModel::Model

  attribute :profile_updates, :boolean, default: true
  attribute :security_alerts, :boolean, default: true
  attribute :feature_announcements, :boolean, default: false
end
