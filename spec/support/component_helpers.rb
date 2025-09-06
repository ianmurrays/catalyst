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
  end

  # Create a mock user for testing
  def create_mock_user(name: "Test User", email: "test@example.com")
    double("User", name: name, email: email)
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers
end
