FactoryBot.define do
  factory :invitation do
    team
    association :created_by, factory: :user
    token { SecureRandom.urlsafe_base64(32) }
    role { :member }
    expires_at { 1.week.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :used do
      used_at { 1.hour.ago }
      association :used_by, factory: :user
    end

    trait :never_expires do
      expires_at { nil }
    end

    trait :owner_role do
      role { :owner }
    end

    trait :admin_role do
      role { :admin }
    end

    trait :viewer_role do
      role { :viewer }
    end
  end
end
