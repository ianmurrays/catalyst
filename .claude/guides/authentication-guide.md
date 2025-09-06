# Authentication Guide

## Overview

Catalyst uses Auth0 for authentication with a modular approach that separates concerns between authentication flow, state management, and authorization.

## Architecture

### Core Components

- **`Auth0Controller`** - Handles OAuth flow (callback, failure, logout)
- **`AuthProvider` concern** - Manages authentication state (`logged_in?`, `current_user`, etc.)
- **`Secured` concern** - Provides authorization for protected controllers
- **CSRF protection** via `omniauth-rails_csrf_protection`

### AuthProvider Concern

```ruby
# app/controllers/concerns/auth_provider.rb
module AuthProvider
  extend ActiveSupport::Concern

  included do
    helper_method :logged_in?
    helper_method :current_auth_provider_user
    helper_method :current_user
  end

  def current_auth_provider_user
    @current_auth_provider_user ||= session[:userinfo]
  end

  def current_user
    return nil unless logged_in?
    @current_user ||= User.find_or_create_from_auth_provider(current_auth_provider_user)
  end

  def logged_in?
    session[:userinfo].present?
  end
end
```

### Secured Concern

```ruby
# app/controllers/concerns/secured.rb
module Secured
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  private

  def require_authentication
    unless logged_in?
      session[:return_to] = request.fullpath
      redirect_to "/auth/auth0", allow_other_host: true
    end
  end
end
```

## Usage Patterns

### Protecting Controllers
```ruby
class ProfileController < ApplicationController
  include AuthProvider
  include Secured  # This controller requires authentication
  
  def show
    # current_user is available here
  end
end
```

### Optional Authentication
```ruby
class PagesController < ApplicationController
  include AuthProvider  # Only include AuthProvider, not Secured
  
  def home
    if logged_in?
      # Show authenticated content
    else
      # Show public content
    end
  end
end
```

### In Views
```ruby
# app/views/layout/navbar.rb
if logged_in?
  span { t("navigation.greeting", name: current_user.name) }
  link_to t("navigation.logout"), logout_path, method: :delete
else
  link_to t("navigation.login"), "/auth/auth0"
end
```

## Email Requirements

**CRITICAL**: All social providers MUST be configured to provide email addresses, as the application requires email for user creation.

### Required Scopes by Provider

- **GitHub**: `user:email` (grants access to user's email addresses)
- **Google**: `email` (grants access to email address) 
- **Facebook**: `email` (grants access to primary email)
- **Twitter**: Email is provided by default if available

### Configuration Steps

#### 1. GitHub OAuth App
- Go to Settings > Developer settings > OAuth Apps
- Edit your application
- Ensure "Request user authorization for email" is enabled
- Users must have verified email addresses visible in their profile

#### 2. Google OAuth
- In Google Cloud Console
- OAuth consent screen must include email scope
- Users will see email permission request

#### 3. Auth0 Dashboard
- Connections > Social
- Edit your social connection
- Ensure email scope is included in the scopes field

### Error Handling

If a provider doesn't supply an email address, authentication will fail with a user-friendly error message:

```ruby
# In Auth0Controller#callback
rescue ArgumentError => e
  # Email is missing from provider
  Rails.logger.error "Authentication failed: #{e.message}"
  render Views::Auth0::Failure.new(error_msg: e.message), status: :unprocessable_content
end
```

## Auth0 Configuration

### Environment Variables
```bash
# Required in .env or environment
AUTH0_DOMAIN=your-domain.auth0.com
AUTH0_CLIENT_ID=your-client-id
AUTH0_CLIENT_SECRET=your-client-secret
```

### Rails Credentials
```ruby
# Use Rails credentials for production
Rails.application.credentials.auth0.domain
Rails.application.credentials.auth0.client_id
Rails.application.credentials.auth0.client_secret
```

### Omniauth Configuration
```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    Rails.application.credentials.auth0.client_id,
    Rails.application.credentials.auth0.client_secret,
    Rails.application.credentials.auth0.domain,
    callback_path: "/auth/auth0/callback",
    authorize_params: {
      scope: "openid email profile"
    },
    session_params: {
      "auth0Client" => Base64.urlsafe_encode64({
        "name" => "omniauth-auth0",
        "version" => OmniauthAuth0::VERSION
      }.to_json)
    }
  )
end
```

## Routes

```ruby
# config/routes.rb
# Auth0
get "/auth/auth0/callback" => "auth0#callback"
get "/auth/failure" => "auth0#failure"
delete "/auth/logout" => "auth0#logout"
```

## User Model Integration

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def self.find_or_create_from_auth_provider(auth_info)
    email = auth_info['email']
    raise ArgumentError, "Email is required from authentication provider" if email.blank?
    
    find_or_create_by(email: email) do |user|
      user.name = auth_info['name']
      user.auth_provider_id = auth_info['sub']
    end
  end
end
```

## Testing Authentication

### RSpec Helpers
```ruby
# spec/support/auth_helpers.rb
module AuthHelpers
  def login_as(user)
    session[:userinfo] = {
      'email' => user.email,
      'name' => user.name,
      'sub' => user.auth_provider_id || "auth0|#{SecureRandom.hex(12)}"
    }
  end

  def logout
    session.delete(:userinfo)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :request
end
```

### Controller Specs
```ruby
# spec/controllers/profile_controller_spec.rb
RSpec.describe ProfileController do
  include AuthHelpers

  describe "GET #show" do
    context "when authenticated" do
      let(:user) { create(:user) }
      before { login_as(user) }
      
      it "shows the profile" do
        get :show
        expect(response).to be_successful
      end
    end

    context "when not authenticated" do
      it "redirects to auth0" do
        get :show
        expect(response).to redirect_to("/auth/auth0")
      end
    end
  end
end
```

## Troubleshooting

### Common Issues

1. **"Email is required" errors**
   - Check provider scopes in Auth0 dashboard
   - Verify users have public emails on GitHub
   - Ensure Google OAuth includes email scope

2. **CSRF token errors**  
   - Verify `omniauth-rails_csrf_protection` is installed
   - Check that CSRF is properly configured

3. **Redirect loops**
   - Check that `/auth/auth0/callback` route is accessible
   - Verify Auth0 callback URLs match your routes

4. **Session not persisting**
   - Check session store configuration
   - Verify cookies are being set properly

### Debug Mode
```ruby
# Add to development.rb for debugging
Rails.logger.level = :debug

# In Auth0Controller, add logging
Rails.logger.debug "Auth info: #{request.env['omniauth.auth'].inspect}"
```