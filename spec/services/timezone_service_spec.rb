# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimezoneService, type: :service do
  describe ".available_timezones" do
    it "returns all ActiveSupport::TimeZone objects" do
      timezones = described_class.available_timezones

      expect(timezones).to be_an(Array)
      expect(timezones).not_to be_empty
      expect(timezones.first).to be_a(ActiveSupport::TimeZone)
      expect(timezones.count).to be > 100 # Should have ~150 timezones
    end

    it "includes common timezones" do
      timezone_names = described_class.available_timezones.map(&:name)

      expect(timezone_names).to include("UTC")
      expect(timezone_names).to include("Eastern Time (US & Canada)")
      expect(timezone_names).to include("Pacific Time (US & Canada)")
      expect(timezone_names).to include("London")
    end
  end

  describe ".timezone_options" do
    it "returns formatted options for select dropdowns" do
      options = described_class.timezone_options

      expect(options).to be_an(Array)
      expect(options).not_to be_empty

      # Each option should be [display_name, identifier]
      option = options.first
      expect(option).to be_an(Array)
      expect(option.length).to eq(2)
      expect(option[0]).to be_a(String) # Display name
      expect(option[1]).to be_a(String) # Identifier
    end

    it "includes UTC as an option" do
      options = described_class.timezone_options
      utc_option = options.find { |opt| opt[1] == "UTC" }

      expect(utc_option).to be_present
      expect(utc_option[0]).to eq("(GMT+00:00) UTC")
    end

    it "formats timezone names properly" do
      options = described_class.timezone_options
      eastern_option = options.find { |opt| opt[1] == "Eastern Time (US & Canada)" }

      expect(eastern_option).to be_present
      expect(eastern_option[0]).to include("Eastern")
    end
  end

  describe ".grouped_timezone_options" do
    it "returns timezones grouped by UTC offset" do
      grouped_options = described_class.grouped_timezone_options

      expect(grouped_options).to be_an(Array)
      expect(grouped_options).not_to be_empty

      # Each group should be [offset_label, [timezone_options]]
      group = grouped_options.first
      expect(group).to be_an(Array)
      expect(group.length).to eq(2)
      expect(group[0]).to be_a(String) # Offset label
      expect(group[1]).to be_an(Array) # Timezone options
    end

    it "sorts groups by UTC offset" do
      grouped_options = described_class.grouped_timezone_options

      # Extract the actual offset values for comparison
      offsets = grouped_options.map { |group| extract_offset_from_label(group[0]) }
      expect(offsets).to eq(offsets.sort)
    end

    it "includes expected timezone in first group" do
      grouped_options = described_class.grouped_timezone_options
      first_group_timezones = grouped_options.first[1]

      # Check that the first group has timezones with the most negative offset
      international_dateline = first_group_timezones.find { |tz| tz[1] == "International Date Line West" }
      expect(international_dateline).to be_present
    end
  end

  describe ".valid_timezone?" do
    it "returns true for valid timezone identifiers" do
      expect(described_class.valid_timezone?("UTC")).to be true
      expect(described_class.valid_timezone?("Eastern Time (US & Canada)")).to be true
      expect(described_class.valid_timezone?("Pacific Time (US & Canada)")).to be true
    end

    it "returns false for invalid timezone identifiers" do
      expect(described_class.valid_timezone?("Invalid/Timezone")).to be false
      expect(described_class.valid_timezone?("")).to be false
      expect(described_class.valid_timezone?(nil)).to be false
    end

    it "handles ActiveSupport::TimeZone name format" do
      # Test that it works with the format Rails uses internally
      expect(described_class.valid_timezone?("America/New_York")).to be true
      expect(described_class.valid_timezone?("Europe/London")).to be true
    end
  end

  describe ".find_timezone" do
    it "finds timezone by identifier" do
      timezone = described_class.find_timezone("UTC")

      expect(timezone).to be_a(ActiveSupport::TimeZone)
      expect(timezone.name).to eq("UTC")
    end

    it "finds timezone by Rails-friendly name" do
      timezone = described_class.find_timezone("Eastern Time (US & Canada)")

      expect(timezone).to be_a(ActiveSupport::TimeZone)
      expect(timezone.name).to eq("Eastern Time (US & Canada)")
    end

    it "returns nil for invalid timezone" do
      timezone = described_class.find_timezone("Invalid/Timezone")

      expect(timezone).to be_nil
    end
  end

  private

  def extract_offset_from_label(label)
    # Helper method to extract numeric offset from formatted label for sorting test
    # This is a simplified version - the actual implementation might be different
    if label.include?("+")
      label.split("+")[1].to_f
    elsif label.include?("-")
      -label.split("-")[1].to_f
    else
      0
    end
  end
end
