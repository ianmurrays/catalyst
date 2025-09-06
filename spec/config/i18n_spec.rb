# frozen_string_literal: true

require "rails_helper"

RSpec.describe "I18n Configuration", type: :request do
  around(:each) do |example|
    # Store original backend state
    original_translations = I18n.backend.instance_variable_get(:@translations).dup

    example.run

    # Restore original state to prevent test pollution
    I18n.backend.instance_variable_set(:@translations, original_translations)
    I18n.backend.reload!
  end
  describe "available locales" do
    it "includes English, Spanish, and Danish locales" do
      expect(I18n.available_locales).to include(:en, :es, :da)
    end

    it "has exactly three available locales" do
      expect(I18n.available_locales.size).to eq(3)
    end

    it "sets English as the default locale" do
      expect(I18n.default_locale).to eq(:en)
    end
  end

  describe "locale files" do
    it "loads English locale file without errors" do
      expect { I18n.t("application.name", locale: :en) }.not_to raise_error
    end

    it "loads Spanish locale file without errors" do
      expect { I18n.t("application.name", locale: :es) }.not_to raise_error
    end

    it "loads Danish locale file without errors" do
      expect { I18n.t("application.name", locale: :da) }.not_to raise_error
    end
  end

  describe "fallback configuration" do
    it "enables fallbacks" do
      expect(I18n.fallbacks).to be_present
      expect(I18n.fallbacks).to be_a(I18n::Locale::Fallbacks)
    end

    it "falls back to English for missing Spanish translations" do
      # Temporarily add a key that only exists in English
      I18n.backend.store_translations(:en, test_fallback: "English text")

      I18n.with_locale(:es) do
        expect(I18n.t(:test_fallback)).to eq("English text")
      end
    end

    it "falls back to English for missing Danish translations" do
      # Temporarily add a key that only exists in English
      I18n.backend.store_translations(:en, test_fallback_da: "English text")

      I18n.with_locale(:da) do
        expect(I18n.t(:test_fallback_da)).to eq("English text")
      end
    end
  end

  describe "date and time localization" do
    let(:test_date) { Date.new(2024, 1, 15) }
    let(:test_time) { Time.new(2024, 1, 15, 14, 30, 0, "+00:00") }

    it "formats dates according to locale" do
      I18n.with_locale(:en) do
        expect(I18n.l(test_date, format: :short)).to match(/Jan/)
      end
    end

    it "formats times according to locale" do
      I18n.with_locale(:en) do
        expect(I18n.l(test_time)).to be_present
      end
    end
  end

  describe "pluralization rules" do
    before do
      # Add test pluralization keys
      I18n.backend.store_translations(:en, {
        item: {
          zero: "no items",
          one: "one item",
          other: "%{count} items"
        }
      })

      I18n.backend.store_translations(:es, {
        item: {
          zero: "ningún elemento",
          one: "un elemento",
          other: "%{count} elementos"
        }
      })

      I18n.backend.store_translations(:da, {
        item: {
          zero: "ingen elementer",
          one: "et element",
          other: "%{count} elementer"
        }
      })
    end

    it "handles English pluralization correctly" do
      I18n.with_locale(:en) do
        expect(I18n.t(:item, count: 0)).to eq("no items")
        expect(I18n.t(:item, count: 1)).to eq("one item")
        expect(I18n.t(:item, count: 2)).to eq("2 items")
      end
    end

    it "handles Spanish pluralization correctly" do
      I18n.with_locale(:es) do
        expect(I18n.t(:item, count: 0)).to eq("ningún elemento")
        expect(I18n.t(:item, count: 1)).to eq("un elemento")
        expect(I18n.t(:item, count: 2)).to eq("2 elementos")
      end
    end

    it "handles Danish pluralization correctly" do
      I18n.with_locale(:da) do
        expect(I18n.t(:item, count: 0)).to eq("ingen elementer")
        expect(I18n.t(:item, count: 1)).to eq("et element")
        expect(I18n.t(:item, count: 2)).to eq("2 elementer")
      end
    end
  end
end
