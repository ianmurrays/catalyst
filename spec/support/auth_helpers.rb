# frozen_string_literal: true

module AuthHelpers
  def login_as(user)
    if respond_to?(:session)
      # For controller specs
      session[:userinfo] = {
        'email' => user.email,
        'name' => user.name,
        'sub' => user.auth_provider_id || "auth0|#{SecureRandom.hex(12)}"
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
              "sub" => user.auth_provider_id || "auth0|#{SecureRandom.hex(12)}"
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
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :component
end
