FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    sequence(:slug) { |n| "team-#{n}" }

    trait :with_members do
      after(:create) do |team|
        create(:membership, :owner, team: team)
        create(:membership, :admin, team: team)
        create(:membership, :member, team: team)
      end
    end

    trait :deleted do
      deleted_at { 1.week.ago }
    end
  end
end
