# frozen_string_literal: true

class LocaleService
  def self.available_locales
    # Parse top-level locale keys from all YAML files to avoid treating filenames as locales
    locale_files = Dir.glob(Rails.root.join("config", "locales", "*.yml"))
    locales = locale_files.flat_map do |file|
      begin
        yaml = YAML.safe_load(File.read(file), permitted_classes: [], aliases: true) || {}
        yaml.keys
      rescue StandardError
        []
      end
    end
    locales.map { |key| key.to_s.to_sym }.uniq
  end

  def self.language_options
    available_locales.map do |locale|
      [ format_language_option(locale), locale.to_s ]
    end
  end

  def self.locale_name(locale, native: true)
    key = native ? "languages.native.#{locale}" : "languages.translated.#{locale}"
    I18n.t(key)
  end

  private

  def self.format_language_option(locale)
    native_name = locale_name(locale, native: true)
    translated_name = locale_name(locale, native: false)

    if native_name == translated_name
      native_name
    else
      "#{native_name} (#{translated_name})"
    end
  end
end
