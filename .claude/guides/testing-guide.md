# Testing Guide

## Testing Stack

Catalyst uses a comprehensive testing stack designed for Rails applications with Phlex components:

- **RSpec** - Primary testing framework
- **FactoryBot** - Test data creation
- **Shoulda Matchers** - Simplified model testing
- **Rails Controller Testing** - Controller specification helpers

## Quick Commands

```bash
bundle exec rspec                  # Run all tests
bundle exec rspec spec/models/     # Run model tests
bundle exec rspec spec/controllers/ # Run controller tests
bundle exec rspec spec/components/ # Run component tests
bundle exec rspec spec/path/to/file_spec.rb  # Run specific test
bundle exec rspec --tag focus     # Run tests tagged with :focus
```

## Testing Patterns

### Model Testing with Shoulda Matchers

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }
  end

  describe "associations" do
    it { should have_many(:posts) }
  end

  describe ".find_or_create_from_auth_provider" do
    it "creates a new user with valid auth info" do
      auth_info = {
        'email' => 'test@example.com',
        'name' => 'Test User',
        'sub' => 'auth0|123'
      }
      
      user = User.find_or_create_from_auth_provider(auth_info)
      
      expect(user).to be_persisted
      expect(user.email).to eq('test@example.com')
    end

    it "raises error when email is missing" do
      auth_info = { 'name' => 'Test User' }
      
      expect {
        User.find_or_create_from_auth_provider(auth_info)
      }.to raise_error(ArgumentError, /Email is required/)
    end
  end
end
```

### Controller Testing with Authentication

```ruby
# spec/controllers/profile_controller_spec.rb
RSpec.describe ProfileController, type: :controller do
  include AuthHelpers

  describe "GET #show" do
    context "when authenticated" do
      let(:user) { create(:user) }
      
      before { login_as(user) }
      
      it "returns success" do
        get :show
        expect(response).to be_successful
      end

      it "assigns current user" do
        get :show
        expect(assigns(:user)).to eq(user)
      end
    end

    context "when not authenticated" do
      it "redirects to auth0" do
        get :show
        expect(response).to redirect_to("/auth/auth0")
      end

      it "stores return path" do
        get :show
        expect(session[:return_to]).to eq(profile_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:user) { create(:user) }
    
    before { login_as(user) }

    it "updates user attributes" do
      patch :update, params: {
        user: { name: "New Name" }
      }
      
      expect(user.reload.name).to eq("New Name")
      expect(response).to redirect_to(profile_path)
    end

    it "handles validation errors" do
      patch :update, params: {
        user: { email: "invalid" }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### Phlex Component Testing

For detailed Phlex component testing patterns, see **@.claude/guides/phlex-testing-guide.md**.

Key principles:
- Use `render_with_view_context(component)` instead of manual mocking
- Test both rendering and behavior
- Use RSpec matchers for HTML assertions

```ruby
# spec/components/layout/navbar_spec.rb
RSpec.describe Layout::Navbar, type: :component do
  include AuthHelpers

  context "when user is logged in" do
    let(:user) { create(:user, name: "John Doe") }
    
    before { login_as(user) }
    
    it "displays user greeting" do
      component = described_class.new
      rendered = render_with_view_context(component)
      
      expect(rendered).to have_text("Hello, John Doe")
      expect(rendered).to have_link("Logout")
    end
  end

  context "when user is not logged in" do
    it "displays login link" do
      component = described_class.new
      rendered = render_with_view_context(component)
      
      expect(rendered).to have_link("Login", href: "/auth/auth0")
      expect(rendered).not_to have_text("Hello")
    end
  end
end
```

### Request Specs for Integration Testing

```ruby
# spec/requests/auth_spec.rb
RSpec.describe "Authentication", type: :request do
  describe "GET /auth/auth0/callback" do
    before do
      # Mock OmniAuth response
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new({
        'extra' => {
          'raw_info' => {
            'email' => 'test@example.com',
            'name' => 'Test User',
            'sub' => 'auth0|123'
          }
        }
      })
    end

    it "creates user and sets session" do
      expect {
        get "/auth/auth0/callback"
      }.to change(User, :count).by(1)
      
      expect(session[:userinfo]).to be_present
      expect(response).to redirect_to(root_path)
    end

    it "handles missing email gracefully" do
      OmniAuth.config.mock_auth[:auth0]['extra']['raw_info'].delete('email')
      
      expect {
        get "/auth/auth0/callback"
      }.not_to change(User, :count)
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

## Factory Definitions

### User Factory

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.full_name }
    auth_provider_id { "auth0|#{SecureRandom.hex(12)}" }
    
    trait :without_name do
      name { nil }
    end
    
    trait :admin do
      role { :admin }
    end
  end
end
```

### Usage in Tests
```ruby
# Create single user
user = create(:user)

# Create user with specific attributes
admin = create(:user, :admin, email: "admin@example.com")

# Build without saving
user = build(:user)

# Create multiple users
users = create_list(:user, 3)
```

## Test Helpers

### Authentication Helper

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

# spec/rails_helper.rb
RSpec.configure do |config|
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :component
end
```

### I18n Testing Helper

```ruby
# spec/support/i18n_helpers.rb
module I18nHelpers
  def with_locale(locale)
    original_locale = I18n.locale
    I18n.locale = locale
    yield
  ensure
    I18n.locale = original_locale
  end
  
  def expect_translation(key, **options)
    expect(I18n.t(key, **options)).not_to include("translation missing")
  end
end

# Usage in tests
it "works in all locales" do
  %i[en es da].each do |locale|
    with_locale(locale) do
      expect_translation("views.home.title")
    end
  end
end
```

## Test Configuration

### RSpec Configuration

```ruby
# spec/rails_helper.rb
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'shoulda/matchers'

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Use transactions for speed
  config.use_transactional_fixtures = true
  
  # Auto-infer spec type from file location
  config.infer_spec_type_from_file_location!
  
  # Focus on tagged tests
  config.filter_run_when_matching :focus
  
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  
  # Clean up after tests
  config.after(:each) do
    # Reset I18n locale
    I18n.locale = I18n.default_locale
  end
end
```

### Database Cleaner (if needed)

```ruby
# spec/support/database_cleaner.rb
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
```

## Testing Best Practices

### 1. Test Structure (Arrange, Act, Assert)

```ruby
it "creates a user with valid attributes" do
  # Arrange
  user_params = { email: "test@example.com", name: "Test User" }
  
  # Act
  user = User.create(user_params)
  
  # Assert
  expect(user).to be_persisted
  expect(user.email).to eq("test@example.com")
end
```

### 2. Use Descriptive Test Names

```ruby
# ❌ Bad
it "works" do

# ✅ Good
it "creates user with valid auth provider info" do
it "redirects unauthenticated users to login" do
it "displays error message when email is missing" do
```

### 3. Test Edge Cases

```ruby
describe "User.find_or_create_from_auth_provider" do
  it "handles missing email" do
    expect {
      User.find_or_create_from_auth_provider({})
    }.to raise_error(ArgumentError)
  end
  
  it "handles empty email" do
    expect {
      User.find_or_create_from_auth_provider({ 'email' => '' })
    }.to raise_error(ArgumentError)
  end
  
  it "finds existing user by email" do
    existing_user = create(:user, email: "test@example.com")
    
    user = User.find_or_create_from_auth_provider({
      'email' => "test@example.com",
      'name' => "Different Name"
    })
    
    expect(user).to eq(existing_user)
  end
end
```

### 4. Mock External Services

```ruby
# For Auth0 testing
before do
  allow(Rails.logger).to receive(:error)
  
  # Mock successful auth
  allow(request.env).to receive(:[]).with("omniauth.auth").and_return({
    "extra" => {
      "raw_info" => {
        "email" => "test@example.com",
        "name" => "Test User"
      }
    }
  })
end
```

### 5. Test Continuous Integration

Run tests as you develop:

```bash
# Test specific area while developing
bundle exec rspec spec/models/user_spec.rb --format documentation

# Run tests automatically on file changes (with guard)
bundle exec guard

# Test with coverage
COVERAGE=true bundle exec rspec
```

### 6. Performance Testing

```ruby
# For testing performance-critical code
it "handles large datasets efficiently" do
  users = create_list(:user, 1000)
  
  expect {
    User.active.includes(:posts).to_a
  }.to perform_under(100).ms
end
```

## Continuous Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.4
        bundler-cache: true
        
    - name: Setup database
      run: |
        bin/rails db:create
        bin/rails db:migrate
        
    - name: Run tests
      run: bundle exec rspec
      
    - name: Run linter
      run: bin/rubocop
```