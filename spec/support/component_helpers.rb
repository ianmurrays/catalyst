# frozen_string_literal: true

module ComponentHelpers
  # Mock Rails helpers commonly needed in component specs
  def mock_rails_helpers_for(component)
    allow(component).to receive(:csrf_meta_tags).and_return('<meta name="csrf-token" content="test-token">')
    allow(component).to receive(:csp_meta_tag).and_return('<meta http-equiv="Content-Security-Policy" content="default-src \'self\'">')
    allow(component).to receive(:stylesheet_link_tag).and_return('<link rel="stylesheet" href="/assets/application.css">')
    allow(component).to receive(:javascript_importmap_tags).and_return('<script>importmap</script>')
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
  end

  # Complete application layout mocking setup
  def setup_application_layout_mocks(component)
    mock_rails_helpers_for(component)
    setup_navbar_mocks
  end

  # Create a mock user for testing
  def create_mock_user(name: "Test User", email: "test@example.com")
    double("User", name: name, email: email)
  end
end

RSpec.configure do |config|
  config.include ComponentHelpers
end
