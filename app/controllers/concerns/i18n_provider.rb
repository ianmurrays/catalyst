module I18nProvider
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
    around_action :with_user_timezone
  end

  private

  def set_locale
    I18n.locale = determine_locale
  rescue StandardError
    begin
      I18n.locale = I18n.default_locale
    rescue StandardError
      # If even setting the default locale fails, continue without changing locale
      Rails.logger.warn "Failed to set locale, continuing with current locale: #{I18n.locale}"
    end
  end

  def determine_locale
    # Priority order for locale selection:
    # 1. User's language preference (if authenticated)
    # 2. Session-stored locale
    # 3. Accept-Language header
    # 4. Default locale

    user_preference_locale ||
      session_locale ||
      extract_locale_from_accept_language_header ||
      I18n.default_locale
  end

  def user_preference_locale
    return unless current_user

    user_locale = current_user.preferences&.language
    return unless user_locale
    return unless LocaleService.available_locales.include?(user_locale.to_sym)

    user_locale.to_sym
  end

  def session_locale
    return unless session[:locale]
    return unless LocaleService.available_locales.include?(session[:locale].to_sym)

    session[:locale].to_sym
  end

  def extract_locale_from_accept_language_header
    return unless request.env["HTTP_ACCEPT_LANGUAGE"]

    # Parse Accept-Language header and find the first supported locale
    accepted_locales = request.env["HTTP_ACCEPT_LANGUAGE"]
                              .split(",")
                              .map { |lang| lang.split(";").first.strip }
                              .map { |lang| lang.split("-").first.strip } # Remove country code (e.g., "es-ES" becomes "es")
                              .map(&:to_sym)

    accepted_locales.find { |locale| LocaleService.available_locales.include?(locale) }
  end

  def with_user_timezone(&block)
    timezone = determine_timezone
    Time.use_zone(timezone, &block)
  end

  def determine_timezone
    # Priority order for timezone selection:
    # 1. User's timezone preference (if authenticated)
    # 2. Default timezone (UTC)

    user_preference_timezone || "UTC"
  end

  def user_preference_timezone
    return unless logged_in?

    # Safely get current user - if user creation fails, just return nil
    user = begin
      current_user
    rescue ArgumentError
      nil
    end

    return unless user

    user_timezone = user.timezone
    return unless user_timezone
    return unless TimezoneService.valid_timezone?(user_timezone)

    user_timezone
  end
end
