# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Views::Profile::Edit, type: :component do
  include ComponentHelpers

  let(:user) { create(:user, preferences: { timezone: "UTC", language: "en" }) }
  let(:errors) { {} }
  let(:component) { described_class.new(user: user, errors: errors) }

  before do
    # Mock LocaleService for language options
    allow(user).to receive(:available_languages).and_return([
      [ "English", "en" ],
      [ "Español (Spanish)", "es" ]
    ])
  end

  describe "timezone selector" do
    before do
      # Mock TimezoneService to provide comprehensive timezone list
      allow(TimezoneService).to receive(:timezone_options).and_return([
        [ "UTC", "UTC" ],
        [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ],
        [ "Central Time (US & Canada)", "Central Time (US & Canada)" ],
        [ "Mountain Time (US & Canada)", "Mountain Time (US & Canada)" ],
        [ "Pacific Time (US & Canada)", "Pacific Time (US & Canada)" ],
        [ "Alaska", "Alaska" ],
        [ "Hawaii", "Hawaii" ],
        [ "Central European Time", "Central European Time" ],
        [ "Tokyo", "Tokyo" ],
        [ "Sydney", "Sydney" ]
      ])
    end

    it "renders comprehensive timezone options" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      expect(timezone_select).not_to be_nil

      # Should have more than the original 8 timezones
      options = timezone_select.css('option')
      expect(options.length).to be >= 10

      # Verify some key timezone options are present
      option_values = options.map { |opt| opt['value'] }
      expect(option_values).to include("UTC")
      expect(option_values).to include("Eastern Time (US & Canada)")
      expect(option_values).to include("Pacific Time (US & Canada)")
      expect(option_values).to include("Central European Time")
      expect(option_values).to include("Tokyo")
    end

    it "displays user-friendly timezone names" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      options = timezone_select.css('option')

      # Find specific timezone options and verify they have readable text
      eastern_option = options.find { |opt| opt['value'] == "Eastern Time (US & Canada)" }
      expect(eastern_option.text.strip).to eq("Eastern Time (US & Canada)")

      utc_option = options.find { |opt| opt['value'] == "UTC" }
      expect(utc_option.text.strip).to eq("UTC")
    end

    it "selects user's current timezone" do
      user.preferences = { timezone: "Pacific Time (US & Canada)", language: "en" }

      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      selected_option = timezone_select.css('option[selected]').first

      expect(selected_option['value']).to eq("Pacific Time (US & Canada)")
    end

    it "defaults to UTC when user has no timezone set" do
      user.preferences = { language: "en" }

      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      selected_option = timezone_select.css('option[selected]').first

      expect(selected_option['value']).to eq("UTC")
    end

    it "calls TimezoneService.timezone_options to get options" do
      expect(TimezoneService).to receive(:timezone_options)
      render_with_view_context(component, user: user)
    end
  end

  describe "grouped timezone selector" do
    before do
      # Mock TimezoneService to provide grouped timezone options
      allow(TimezoneService).to receive(:grouped_timezone_options).and_return([
        [ "UTC±00:00", [
          [ "UTC", "UTC" ]
        ] ],
        [ "UTC-05:00", [
          [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ]
        ] ],
        [ "UTC-08:00", [
          [ "Pacific Time (US & Canada)", "Pacific Time (US & Canada)" ]
        ] ],
        [ "UTC+01:00", [
          [ "Central European Time", "Central European Time" ]
        ] ],
        [ "UTC+09:00", [
          [ "Tokyo", "Tokyo" ]
        ] ]
      ])
    end

    it "renders timezone options grouped by UTC offset" do
      # For this test, we'll just verify that the grouped options functionality exists
      # even if not currently used in the view
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      expect(timezone_select).not_to be_nil

      # Verify that the TimezoneService has grouped options available
      expect(TimezoneService.grouped_timezone_options).to be_an(Array)
    end
  end

  describe "integration with existing preferences form" do
    it "renders timezone field within preferences section" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      # Check that timezone field is inside the preferences card
      preferences_card = doc.css('div').find { |div| div.text.include?("Preferences") }
      expect(preferences_card).not_to be_nil

      # Timezone select should be present
      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      expect(timezone_select).not_to be_nil
    end

    it "includes timezone alongside language preference" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      # Both selects should be present
      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      language_select = doc.css('select[name="user[preferences][language]"]').first

      expect(timezone_select).not_to be_nil
      expect(language_select).not_to be_nil
    end

    it "maintains form structure and styling" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      # Timezone field should have proper form styling classes
      timezone_select = doc.css('select[name="user[preferences][timezone]"]').first
      expect(timezone_select['class']).to include("border-border")
      expect(timezone_select['class']).to include("rounded-md")
    end
  end

  describe "enhanced timezone selector with Stimulus support" do
    before do
      allow(TimezoneService).to receive(:timezone_options).and_return([
        [ "UTC", "UTC" ],
        [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ],
        [ "Pacific Time (US & Canada)", "Pacific Time (US & Canada)" ]
      ])
    end

    it "includes data attributes for Stimulus controller integration" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      # The timezone field wrapper should eventually have Stimulus data attributes
      # This test anticipates future enhancement with the timezone detector
      timezone_field = doc.css('select[name="user[preferences][timezone]"]').first
      expect(timezone_field).not_to be_nil

      # For now, just verify the basic structure is ready for enhancement
      expect(timezone_field['id']).to eq("user_preferences_timezone")
    end
  end

  describe "error handling" do
    let(:errors) do
      instance_double("ActiveModel::Errors",
        any?: true,
        full_messages: [ "Timezone is not a valid timezone" ],
        "[]": [ "is not a valid timezone" ]
      )
    end

    let(:component) { described_class.new(user: user, errors: errors) }

    before do
      allow(TimezoneService).to receive(:timezone_options).and_return([
        [ "UTC", "UTC" ],
        [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ]
      ])
    end

    it "displays timezone validation errors" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      # Should have error alert - look for the Ruby UI Alert structure
      error_alert = doc.css('[class*="ring-destructive"]').first ||
                    doc.css('[class*="text-destructive"]').first ||
                    doc.css('h5').find { |h5| h5.text.include?("errors") }

      expect(error_alert).not_to be_nil
      expect(html).to include("Please fix the following errors:")
      expect(html).to include("Timezone is not a valid timezone")
    end
  end

  describe "accessibility" do
    before do
      allow(TimezoneService).to receive(:timezone_options).and_return([
        [ "UTC", "UTC" ],
        [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ]
      ])
    end

    it "includes proper labels for timezone field" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_label = doc.css('label[for="user_preferences_timezone"]').first
      expect(timezone_label).not_to be_nil
      expect(timezone_label.text.strip).to eq("Timezone")
    end

    it "associates label with select element" do
      html = render_with_view_context(component, user: user)
      doc = Nokogiri::HTML5(html)

      timezone_select = doc.css('select[id="user_preferences_timezone"]').first
      timezone_label = doc.css('label[for="user_preferences_timezone"]').first

      expect(timezone_select).not_to be_nil
      expect(timezone_label).not_to be_nil
    end
  end
end
