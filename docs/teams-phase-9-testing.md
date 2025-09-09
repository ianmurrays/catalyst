# Phase 9: Testing & Quality Assurance

## Objective
Ensure comprehensive test coverage for the entire teams feature, including unit tests, integration tests, and end-to-end user flow testing.

## Test Categories

### 1. Model Tests
Complete coverage for Team, Membership, and Invitation models.

### 2. Policy Tests
Authorization rules for all team-related actions.

### 3. Controller Tests
Request handling and authorization enforcement.

### 4. Service Tests
Business logic in service objects.

### 5. Component Tests
Phlex view components and UI elements.

### 6. Integration Tests
Complete user flows and feature interactions.

### 7. System Tests
Browser-based end-to-end testing.

## Detailed Test Requirements

### Model Specs

#### Team Model
```ruby
# spec/models/team_spec.rb
RSpec.describe Team, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug).scoped_to(:deleted_at) }
  end
  
  describe "associations" do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:invitations).dependent(:destroy) }
  end
  
  describe "slug generation" do
    it "generates slug from name"
    it "handles duplicate slugs"
    it "preserves custom slugs"
  end
  
  describe "soft deletion" do
    it "sets deleted_at timestamp"
    it "excludes deleted teams from queries"
    it "allows undelete"
  end
  
  describe "#add_owner" do
    it "creates membership with owner role"
  end
  
  describe "#member?" do
    it "returns true for team members"
    it "returns false for non-members"
  end
end
```

#### Membership Model
```ruby
# spec/models/membership_spec.rb
RSpec.describe Membership, type: :model do
  describe "validations" do
    it { should validate_uniqueness_of(:user_id).scoped_to(:team_id) }
  end
  
  describe "role enum" do
    it "defines correct roles"
    it "provides role query methods"
  end
  
  describe "scopes" do
    it ".owners returns only owners"
    it ".active excludes deleted teams"
  end
end
```

#### Invitation Model
```ruby
# spec/models/invitation_spec.rb
RSpec.describe Invitation, type: :model do
  describe "token generation" do
    it "generates unique secure tokens"
    it "handles token collisions"
  end
  
  describe "#expired?" do
    it "returns true for expired invitations"
    it "returns false for never-expiring invitations"
  end
  
  describe "#accept!" do
    it "creates membership"
    it "marks invitation as used"
    it "prevents double acceptance"
  end
end
```

### Policy Specs

#### TeamPolicy
```ruby
# spec/policies/team_policy_spec.rb
RSpec.describe TeamPolicy do
  let(:owner) { create(:user) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:team) { create(:team) }
  
  before do
    create(:membership, user: owner, team: team, role: :owner)
    create(:membership, user: admin, team: team, role: :admin)
    create(:membership, user: member, team: team, role: :member)
  end
  
  describe "#update?" do
    it "allows owners" do
      expect(described_class.new(UserContext.new(owner, team), team).update?).to be true
    end
    
    it "allows admins" do
      expect(described_class.new(UserContext.new(admin, team), team).update?).to be true
    end
    
    it "denies members" do
      expect(described_class.new(UserContext.new(member, team), team).update?).to be false
    end
  end
  
  describe "#destroy?" do
    it "allows only owners"
    it "prevents destroying last owner's team"
  end
end
```

### Controller Specs

#### TeamsController
```ruby
# spec/controllers/teams_controller_spec.rb
RSpec.describe TeamsController, type: :controller do
  include AuthHelpers
  
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  
  before do
    login_as(user)
    create(:membership, user: user, team: team, role: :owner)
  end
  
  describe "GET #index" do
    it "lists user's teams"
    it "excludes teams user doesn't belong to"
  end
  
  describe "POST #create" do
    context "when team creation allowed" do
      it "creates team and adds creator as owner"
      it "redirects to team page"
    end
    
    context "when team creation disabled" do
      before { allow(Rails.configuration).to receive(:allow_team_creation).and_return(false) }
      
      it "denies creation"
    end
  end
end
```

### Service Specs

#### InvitationService
```ruby
# spec/services/invitation_service_spec.rb
RSpec.describe InvitationService do
  describe ".create" do
    it "generates unique token"
    it "sets correct expiration"
    it "returns invitation with full URL"
  end
  
  describe ".accept" do
    context "with valid token" do
      it "creates membership"
      it "marks invitation as used"
    end
    
    context "with expired token" do
      it "returns error"
    end
  end
end
```

### Integration Tests

#### Complete User Flows
```ruby
# spec/features/team_onboarding_spec.rb
RSpec.describe "Team Onboarding", type: :feature do
  scenario "new user creates first team" do
    # Login as new user
    # Visit onboarding page
    # Create team
    # Verify redirect and team creation
  end
  
  scenario "user joins via invitation" do
    # Create invitation
    # Visit invitation URL
    # Login/signup
    # Verify team membership
  end
end

# spec/features/team_management_spec.rb
RSpec.describe "Team Management", type: :feature do
  scenario "owner manages team members" do
    # Login as owner
    # View team members
    # Invite new member
    # Change member role
    # Remove member
  end
end
```

### System Tests

#### Browser-based Tests
```ruby
# spec/system/teams_spec.rb
RSpec.describe "Teams", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  it "allows team switching" do
    # Login
    # Click team switcher
    # Select different team
    # Verify context change
  end
  
  it "copies invitation link" do
    # Create invitation
    # Click copy button
    # Verify clipboard content
  end
end
```

## Test Data & Factories

### Factory Updates
```ruby
# spec/factories/teams.rb
FactoryBot.define do
  factory :team do
    name { Faker::Company.name }
    slug { name.parameterize }
    
    trait :with_members do
      after(:create) do |team|
        create_list(:membership, 3, team: team)
      end
    end
    
    trait :deleted do
      deleted_at { 1.day.ago }
    end
  end
end

# spec/factories/memberships.rb
FactoryBot.define do
  factory :membership do
    user
    team
    role { :member }
    
    trait :owner do
      role { :owner }
    end
    
    trait :admin do
      role { :admin }
    end
  end
end

# spec/factories/invitations.rb
FactoryBot.define do
  factory :invitation do
    team
    association :created_by, factory: :user
    token { SecureRandom.urlsafe_base64(32) }
    role { :member }
    expires_at { 1.week.from_now }
    
    trait :expired do
      expires_at { 1.hour.ago }
    end
    
    trait :used do
      used_at { 1.day.ago }
      association :used_by, factory: :user
    end
  end
end
```

## Test Helpers

### Team Test Helpers
```ruby
# spec/support/team_helpers.rb
module TeamHelpers
  def create_team_with_user(user, role: :owner)
    team = create(:team)
    create(:membership, user: user, team: team, role: role)
    team
  end
  
  def set_current_team(team)
    session[:current_team_id] = team.id
  end
end

RSpec.configure do |config|
  config.include TeamHelpers
end
```

## Performance Testing

### N+1 Query Prevention
```ruby
# spec/requests/teams_performance_spec.rb
RSpec.describe "Teams Performance", type: :request do
  it "avoids N+1 queries on team index" do
    user = create(:user)
    create_list(:team, 3) do |team|
      create(:membership, user: user, team: team)
    end
    
    login_as(user)
    
    expect {
      get teams_path
    }.to perform_under(100).and_make_database_queries(count: 5..10)
  end
end
```

## Security Testing

### Authorization Tests
```ruby
# spec/security/team_authorization_spec.rb
RSpec.describe "Team Authorization" do
  it "prevents cross-team access"
  it "validates invitation tokens securely"
  it "prevents role escalation"
  it "enforces soft delete permissions"
end
```

## Configuration Testing

### Environment-based Tests
```ruby
# spec/configuration/teams_config_spec.rb
RSpec.describe "Teams Configuration" do
  it "respects teams_enabled setting"
  it "enforces allow_team_creation"
  it "handles configuration changes gracefully"
end
```

## Test Execution

### Running Tests
```bash
# Run all team-related tests
bundle exec rspec spec --tag teams

# Run specific test types
bundle exec rspec spec/models
bundle exec rspec spec/policies
bundle exec rspec spec/features

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Continuous Integration
```yaml
# .github/workflows/test.yml
- name: Run team feature tests
  run: |
    bundle exec rspec spec/models/team*
    bundle exec rspec spec/features/team*
```

## Quality Metrics

### Coverage Goals
- Line coverage: > 95%
- Branch coverage: > 90%
- Policy coverage: 100%
- Integration coverage: All user flows

### Performance Targets
- Model tests: < 100ms each
- Controller tests: < 200ms each
- Feature tests: < 2s each
- System tests: < 5s each

## Key Testing Principles

1. **Test Behavior, Not Implementation**
2. **Use Factories for Consistency**
3. **Test Edge Cases**
4. **Maintain Test Independence**
5. **Keep Tests Fast**
6. **Test Error Conditions**
7. **Document Complex Scenarios**