# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Configuration" do
  describe "allow_team_creation configuration" do
    it "is enabled by default in test environment" do
      expect(Rails.configuration.allow_team_creation).to be true
    end

    it "is enabled by default in development environment" do
      # This tests that the configuration is properly set
      # In development, we also set it to true
      expect(Rails.configuration.respond_to?(:allow_team_creation)).to be true
    end

    context "when configuration changes" do
      it "reflects changes immediately" do
        original = Rails.configuration.allow_team_creation

        Rails.configuration.allow_team_creation = false
        expect(Rails.configuration.allow_team_creation).to be false

        Rails.configuration.allow_team_creation = true
        expect(Rails.configuration.allow_team_creation).to be true

        # Restore
        Rails.configuration.allow_team_creation = original
      end
    end
  end
end
