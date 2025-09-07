FactoryBot.define do
  factory :user do
    sequence(:auth0_sub) { |n| "auth0|#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "Test User" }
    bio { "A test user bio" }
    preferences { UserPreferences.new }
  end
end
