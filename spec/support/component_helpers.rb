# frozen_string_literal: true

require "nokogiri"

module ComponentHelpers
  # Phlex component rendering helper following best practices
  def render(component)
    component.call
  end

  # HTML fragment parsing for component testing
  def render_fragment(component = nil, &block)
    html = if component
      if block
        component.call(&block)
      else
        component.call
      end
    else
      block.call
    end
    Nokogiri::HTML5.fragment(html)
  end

  # Full HTML document parsing
  def render_document(component = nil, &block)
    html = if component
      if block
        component.call(&block)
      else
        component.call
      end
    else
      block.call
    end
    Nokogiri::HTML5(html)
  end

  # Mock Rails helpers commonly needed in component specs
  def mock_rails_helpers_for(component)
    # These helpers output HTML directly, so we'll stub them to insert the HTML into the component's output
    allow(component).to receive(:csrf_meta_tags) do
      # Return nil as these are output helpers that render directly
      nil
    end

    allow(component).to receive(:csp_meta_tag) do
      # Return nil as these are output helpers that render directly
      nil
    end

    allow(component).to receive(:stylesheet_link_tag) do |*args|
      # Return nil as these are output helpers that render directly
      nil
    end

    allow(component).to receive(:javascript_importmap_tags) do
      # Return nil as these are output helpers that render directly
      nil
    end
  end

  # Helper to create raw HTML for Phlex components
  def raw(html)
    html.html_safe
  end

  # Mock authentication helpers for navbar components
  def mock_navbar_auth_helpers(logged_in: false, user: nil)
    allow_any_instance_of(Components::Layout::Navbar).to receive(:logged_in?).and_return(logged_in)
    allow_any_instance_of(Components::Layout::Navbar).to receive(:current_user).and_return(user)
    allow_any_instance_of(Components::Layout::Navbar).to receive(:form_authenticity_token).and_return("test-token")
  end

  # Mock I18n translations for navbar
  def mock_navbar_translations
    allow_any_instance_of(Components::Layout::Navbar).to receive(:t) do |key, **options|
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
      else
        key.to_s
      end
    end
  end

  # Mock I18n for view components
  def mock_view_translations_for(component)
    allow(component).to receive(:t) do |key, **options|
      case key
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
      else
        key.to_s
      end
    end
  end

  # Complete navbar component mocking setup
  def setup_navbar_mocks(logged_in: false, user: nil)
    mock_navbar_auth_helpers(logged_in: logged_in, user: user)
    mock_navbar_translations

    # Create a mock Phlex component for navbar
    mock_navbar_class = Class.new(Phlex::HTML) do
      def initialize(logged_in: false, user: nil)
        @logged_in = logged_in
        @user = user
      end

      def view_template
        header(class: "sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-2xl backdrop-saturate-200 block") do
          div(class: "w-full max-w-none px-4 flex h-14 items-center justify-between") do
            div(class: "flex items-center") do
              h1(class: "text-xl font-bold text-foreground") { "Catalyst" }
            end
            div(class: "flex items-center gap-4") do
              if @logged_in
                render_logged_in_nav
              else
                render_logged_out_nav
              end
            end
          end
        end
      end

      private

      def render_logged_out_nav
        form(action: "/auth/auth0", method: "post", "data-turbo": "false") do
          input(type: "hidden", name: "authenticity_token", value: "test-token")
          button(type: "submit", class: "cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm") { "Login" }
        end
      end

      def render_logged_in_nav
        span(class: "text-muted-foreground") { "Hello, #{@user.name}" }
        a(href: "/profile", class: "inline-flex") do
          button(class: "cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm") { "Profile" }
        end
        form(action: "/auth/logout", method: "post", "data-turbo": "false") do
          input(type: "hidden", name: "authenticity_token", value: "test-token")
          input(type: "hidden", name: "_method", value: "delete")
          button(type: "submit", class: "cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm") { "Logout" }
        end
      end
    end

    allow(Components::Layout::Navbar).to receive(:new).and_return(mock_navbar_class.new(logged_in: logged_in, user: user))
  end

  # Complete application layout mocking setup
  def setup_application_layout_mocks(component)
    mock_rails_helpers_for(component)
    setup_navbar_mocks

    # Also mock translations for the component itself in case it has any
    allow(component).to receive(:t) do |key, **options|
      case key
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
      else
        key.to_s
      end
    end
  end

  # Create a mock view context for Rails integration
  def view_context
    @view_context ||= ActionView::TestCase::TestController.new.view_context
  end

  # Helper for rendering components with Rails integration
  def render_with_view_context(component)
    component.call(view_context: view_context)
  end

  # Create a mock user for testing
  def create_mock_user(name: "Test User", email: "test@example.com")
    double("User", name: name, email: email)
  end

  private

  def logged_out_nav_html
    '<form action="/auth/auth0" method="post" data-turbo="false">' +
      '<input type="hidden" name="authenticity_token" value="test-token">' +
      '<button type="submit" class="cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm">Login</button>' +
    '</form>'
  end

  def logged_in_nav_html(user)
    '<span class="text-muted-foreground">Hello, ' + user.name + '</span>' +
    '<a href="/profile" class="inline-flex">' +
      '<button class="cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm">Profile</button>' +
    '</a>' +
    '<form action="/auth/logout" method="post" data-turbo="false">' +
      '<input type="hidden" name="authenticity_token" value="test-token">' +
      '<input type="hidden" name="_method" value="delete">' +
      '<button type="submit" class="cursor-pointer whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground px-4 py-2 h-9 text-sm">Logout</button>' +
    '</form>'
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers
end
