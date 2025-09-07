# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailNotificationPreferences, type: :model do
  describe "attributes" do
    subject(:preferences) { described_class.new }

    it "has boolean attributes with defaults" do
      expect(preferences.profile_updates).to be true
      expect(preferences.security_alerts).to be true
      expect(preferences.feature_announcements).to be false
    end
  end

  describe "instantiation" do
    it "can be created with custom values" do
      preferences = described_class.new(
        profile_updates: false,
        security_alerts: true,
        feature_announcements: true
      )

      expect(preferences.profile_updates).to be false
      expect(preferences.security_alerts).to be true
      expect(preferences.feature_announcements).to be true
    end

    it "can be created from hash using new" do
      preferences = described_class.new(
        profile_updates: false,
        security_alerts: false,
        feature_announcements: true
      )

      expect(preferences.profile_updates).to be false
      expect(preferences.security_alerts).to be false
      expect(preferences.feature_announcements).to be true
    end
  end

  describe "serialization" do
    it "serializes to JSON correctly" do
      preferences = described_class.new(
        profile_updates: false,
        security_alerts: true,
        feature_announcements: true
      )

      json = preferences.as_json

      expect(json).to eq({
        "profile_updates" => false,
        "security_alerts" => true,
        "feature_announcements" => true
      })
    end
  end
end
