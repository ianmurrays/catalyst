# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPreferences, type: :model do
  describe "attributes" do
    subject(:preferences) { described_class.new }

    it "has default values" do
      expect(preferences.language).to be_nil  # Language has no default - handled by User model
      expect(preferences.timezone).to eq("UTC")
      expect(preferences.email_notifications).to be_an(EmailNotificationPreferences)
    end
  end

  describe "validations" do
    subject(:preferences) { described_class.new }

    it "validates language inclusion" do
      preferences.language = "invalid"
      expect(preferences).not_to be_valid
      expect(preferences.errors[:language]).to include("is not included in the list")
    end

    it "accepts valid languages" do
      LocaleService.available_locales.each do |locale|
        preferences.language = locale.to_s
        preferences.valid?
        expect(preferences.errors[:language]).to be_empty
      end
    end

    it "validates timezone inclusion" do
      preferences.timezone = "Invalid/Timezone"
      expect(preferences).not_to be_valid
      expect(preferences.errors[:timezone]).to include("is not included in the list")
    end

    it "accepts valid timezones" do
      preferences.timezone = "Eastern Time (US & Canada)"
      expect(preferences).to be_valid

      preferences.timezone = "UTC"
      expect(preferences).to be_valid
    end

    it "validates nested email_notifications" do
      # This should be valid by default
      expect(preferences).to be_valid
      expect(preferences.errors[:email_notifications]).to be_empty
    end
  end

  describe "nested email notifications" do
    it "has properly initialized email notifications" do
      preferences = described_class.new

      expect(preferences.email_notifications.profile_updates).to be true
      expect(preferences.email_notifications.security_alerts).to be true
      expect(preferences.email_notifications.feature_announcements).to be false
    end

    it "can update nested email notifications" do
      preferences = described_class.new
      preferences.email_notifications.profile_updates = false

      expect(preferences.email_notifications.profile_updates).to be false
    end
  end

  describe "timezone_object method" do
    it "returns ActiveSupport::TimeZone object" do
      preferences = described_class.new(timezone: "America/New_York")

      timezone_obj = preferences.timezone_object
      expect(timezone_obj).to be_an(ActiveSupport::TimeZone)
      expect(timezone_obj.name).to eq("America/New_York")
    end

    it "returns nil for invalid timezone" do
      preferences = described_class.new(timezone: "Invalid/Timezone")

      timezone_obj = preferences.timezone_object
      expect(timezone_obj).to be_nil
    end
  end

  describe "instantiation with new" do
    it "handles nested attributes correctly" do
      preferences = described_class.new(
        language: "es",
        timezone: "Eastern Time (US & Canada)",
        email_notifications: EmailNotificationPreferences.new(
          profile_updates: false,
          security_alerts: true,
          feature_announcements: true
        )
      )

      expect(preferences.language).to eq("es")
      expect(preferences.timezone).to eq("Eastern Time (US & Canada)")
      expect(preferences.email_notifications.profile_updates).to be false
      expect(preferences.email_notifications.security_alerts).to be true
      expect(preferences.email_notifications.feature_announcements).to be true
    end

    it "handles partial attributes with defaults" do
      preferences = described_class.new(
        language: "da"
      )

      expect(preferences.language).to eq("da")
      expect(preferences.timezone).to eq("UTC")
      expect(preferences.email_notifications).to be_an(EmailNotificationPreferences)
    end
  end

  describe "serialization" do
    it "serializes to JSON correctly with nested attributes" do
      preferences = described_class.new(
        language: "es",
        timezone: "Europe/Madrid"
      )
      preferences.email_notifications.feature_announcements = true

      json = preferences.as_json

      expect(json).to include({
        "language" => "es",
        "timezone" => "Europe/Madrid",
        "email_notifications" => {
          "profile_updates" => true,
          "security_alerts" => true,
          "feature_announcements" => true
        }
      })
    end
  end
end
