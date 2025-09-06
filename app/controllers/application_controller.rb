class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Disable Rails layouts - Phlex handles all layout rendering
  layout false

  include AuthProvider

  before_action :set_locale

  private

  def set_locale
    I18n.locale = determine_locale
  rescue I18n::InvalidLocale
    I18n.locale = I18n.default_locale
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

    user_locale = current_user.preferences&.dig("language")
    return unless user_locale
    return unless I18n.available_locales.include?(user_locale.to_sym)

    user_locale.to_sym
  end

  def session_locale
    return unless session[:locale]
    return unless I18n.available_locales.include?(session[:locale].to_sym)

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

    accepted_locales.find { |locale| I18n.available_locales.include?(locale) }
  end
end
