# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocaleService do
  describe ".available_locales" do
    it "returns locales found in config/locales/*.yml files" do
      allow(Dir).to receive(:glob).with(Rails.root.join("config", "locales", "*.yml")).and_return([
        Rails.root.join("config", "locales", "en.yml"),
        Rails.root.join("config", "locales", "es.yml"),
        Rails.root.join("config", "locales", "da.yml")
      ])

      expect(LocaleService.available_locales).to contain_exactly(:en, :es, :da)
    end

    it "returns empty array when no locale files exist" do
      allow(Dir).to receive(:glob).and_return([])

      expect(LocaleService.available_locales).to eq([])
    end
  end

  describe ".language_options" do
    before do
      allow(LocaleService).to receive(:available_locales).and_return([ :en, :es, :da ])
    end

    context "when current locale is :en" do
      it "returns formatted options with native names and English translations" do
        I18n.with_locale(:en) do
          allow(I18n).to receive(:t).with("languages.native.en").and_return("English")
          allow(I18n).to receive(:t).with("languages.native.es").and_return("Español")
          allow(I18n).to receive(:t).with("languages.native.da").and_return("Dansk")
          allow(I18n).to receive(:t).with("languages.translated.en").and_return("English")
          allow(I18n).to receive(:t).with("languages.translated.es").and_return("Spanish")
          allow(I18n).to receive(:t).with("languages.translated.da").and_return("Danish")

          options = LocaleService.language_options

          expect(options).to contain_exactly(
            [ "English", "en" ],
            [ "Español (Spanish)", "es" ],
            [ "Dansk (Danish)", "da" ]
          )
        end
      end
    end

    context "when current locale is :es" do
      it "returns formatted options with native names and Spanish translations" do
        I18n.with_locale(:es) do
          allow(I18n).to receive(:t).with("languages.native.en").and_return("English")
          allow(I18n).to receive(:t).with("languages.native.es").and_return("Español")
          allow(I18n).to receive(:t).with("languages.native.da").and_return("Dansk")
          allow(I18n).to receive(:t).with("languages.translated.en").and_return("Inglés")
          allow(I18n).to receive(:t).with("languages.translated.es").and_return("Español")
          allow(I18n).to receive(:t).with("languages.translated.da").and_return("Danés")

          options = LocaleService.language_options

          expect(options).to contain_exactly(
            [ "English (Inglés)", "en" ],
            [ "Español", "es" ],
            [ "Dansk (Danés)", "da" ]
          )
        end
      end
    end

    context "when current locale is :da" do
      it "returns formatted options with native names and Danish translations" do
        I18n.with_locale(:da) do
          allow(I18n).to receive(:t).with("languages.native.en").and_return("English")
          allow(I18n).to receive(:t).with("languages.native.es").and_return("Español")
          allow(I18n).to receive(:t).with("languages.native.da").and_return("Dansk")
          allow(I18n).to receive(:t).with("languages.translated.en").and_return("Engelsk")
          allow(I18n).to receive(:t).with("languages.translated.es").and_return("Spansk")
          allow(I18n).to receive(:t).with("languages.translated.da").and_return("Dansk")

          options = LocaleService.language_options

          expect(options).to contain_exactly(
            [ "English (Engelsk)", "en" ],
            [ "Español (Spansk)", "es" ],
            [ "Dansk", "da" ]
          )
        end
      end
    end
  end

  describe ".locale_name" do
    before do
      allow(I18n).to receive(:t).with("languages.native.en").and_return("English")
      allow(I18n).to receive(:t).with("languages.native.es").and_return("Español")
      allow(I18n).to receive(:t).with("languages.native.da").and_return("Dansk")
      allow(I18n).to receive(:t).with("languages.translated.en").and_return("Inglés")
      allow(I18n).to receive(:t).with("languages.translated.es").and_return("Español")
      allow(I18n).to receive(:t).with("languages.translated.da").and_return("Danés")
    end

    context "when native: true" do
      it "returns the native language name" do
        expect(LocaleService.locale_name(:es, native: true)).to eq("Español")
        expect(LocaleService.locale_name(:en, native: true)).to eq("English")
        expect(LocaleService.locale_name(:da, native: true)).to eq("Dansk")
      end
    end

    context "when native: false" do
      it "returns the translated language name" do
        I18n.with_locale(:es) do
          expect(LocaleService.locale_name(:en, native: false)).to eq("Inglés")
          expect(LocaleService.locale_name(:es, native: false)).to eq("Español")
          expect(LocaleService.locale_name(:da, native: false)).to eq("Danés")
        end
      end
    end
  end

  describe ".format_language_option" do
    before do
      allow(I18n).to receive(:t).with("languages.native.es").and_return("Español")
      allow(I18n).to receive(:t).with("languages.translated.es").and_return("Spanish")
    end

    it "returns native name with translation in parentheses when different" do
      I18n.with_locale(:en) do
        expect(LocaleService.send(:format_language_option, :es)).to eq("Español (Spanish)")
      end
    end

    it "returns only native name when native and translated are the same" do
      allow(I18n).to receive(:t).with("languages.translated.es").and_return("Español")

      I18n.with_locale(:es) do
        expect(LocaleService.send(:format_language_option, :es)).to eq("Español")
      end
    end
  end
end
