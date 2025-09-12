# frozen_string_literal: true

module AuthHelpers
  def login_as(user)
    if respond_to?(:session)
      # For controller specs
      session[:userinfo] = {
        'email' => user.email,
        'name' => user.name,
        'sub' => user.auth0_sub || "auth0|#{SecureRandom.hex(12)}"
      }
    else
      # For request specs - we need to make a request that sets the session
      # This is a simplified approach - in practice you might mock the auth callback
      post "/auth/auth0/callback", env: {
        "omniauth.auth" => OmniAuth::AuthHash.new({
          "extra" => {
            "raw_info" => {
              "email" => user.email,
              "name" => user.name,
              "sub" => user.auth0_sub || "auth0|#{SecureRandom.hex(12)}"
            }
          }
        })
      }
    end
  end

  def logout
    if respond_to?(:session)
      session.delete(:userinfo)
    else
      delete "/auth/logout"
    end
  end

  # Helper to simulate Auth0 callback for request specs
  def simulate_auth_callback(user_info)
    # Temporarily disable CSRF protection for OmniAuth
    original_csrf = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    # Enable OmniAuth test mode for this request
    OmniAuth.config.test_mode = true

    # Create mock auth hash
    OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new({
      "extra" => {
        "raw_info" => user_info
      }
    })

    # Make the callback request with proper env setup
    get "/auth/auth0/callback", env: {
      "omniauth.auth" => OmniAuth.config.mock_auth[:auth0]
    }

    # Clean up
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:auth0] = nil
    OmniAuth.config.request_validation_phase = original_csrf
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :component
end
