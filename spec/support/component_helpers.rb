# frozen_string_literal: true

require "nokogiri"

module ComponentHelpers
  # HTML fragment parsing for component testing
  def render_fragment(component)
    html = render_with_view_context(component)
    Nokogiri::HTML5.fragment(html)
  end

  # Create a mock view context for Rails integration
  def view_context
    @view_context ||= ActionView::TestCase::TestController.new.view_context
  end

  # Helper for rendering components with Rails integration
  def render_with_view_context(component, user: nil, &block)
    setup_view_context_helpers(user: user)
    if block
      view_context.render(component, &block)
    else
      view_context.render(component)
    end
  end

  # Set up global view context helpers for all components
  def setup_view_context_helpers(user: nil)
    # Add authentication helpers to the view context
    view_context.define_singleton_method(:logged_in?) { user.present? }
    view_context.define_singleton_method(:current_user) { user }
    view_context.define_singleton_method(:form_authenticity_token) { "test-token" }

    # Add translation helper to the view context
    view_context.define_singleton_method(:t) do |key, **options|
      case key.to_s
      when "application.name"
        "Catalyst"
      when "navigation.login"
        "Login"
      when "navigation.logout"
        "Logout"
      when "navigation.profile"
        "Profile"
      when "navigation.greeting"
        if options[:name]
          "Hello, #{options[:name]}"
        else
          "Hello, Guest"
        end
      when "views.profile.edit.title"
        "Edit Profile"
      when "views.profile.edit.subtitle"
        "Update your profile information"
      when "views.profile.edit.preferences.title"
        "Preferences"
      when "views.profile.edit.preferences.description"
        "Customize your experience"
      when "common.labels.timezone"
        "Timezone"
      when "common.labels.language"
        "Language"
      when "common.buttons.save_changes"
        "Save Changes"
      when "common.buttons.cancel"
        "Cancel"
      when "views.profile.edit.validation_errors"
        "Please fix the following errors:"
      else
        key.to_s
      end
    end
  end

  # Create a mock user for testing
  def create_mock_user(name: "Test User", email: "test@example.com")
    double("User", name: name, email: email)
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers
end
