FactoryBot.define do
  factory :user do
    sequence(:auth0_sub) { |n| "auth0|#{n}" }
    display_name { "Test User" }
    bio { "A test user bio" }
    preferences { User.send(:default_preferences) }
  end
end
