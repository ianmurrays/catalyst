# Phase 8: Configuration & Settings

## Objective
Implement environment-based configuration for team features, specifically for controlling team creation across different environments.

## Configuration Strategy

### Environment Files
Configuration should live in environment-specific files, not in an initializer, to allow different settings per environment.

### Key Settings
1. **allow_team_creation**: Whether users can create new teams (only configuration needed)

## Implementation

### Environment Configuration
```ruby
# config/environments/development.rb
Rails.application.configure do
  # ... existing config ...

  # Team feature configuration
  config.allow_team_creation = true
end

# config/environments/test.rb
Rails.application.configure do
  # ... existing config ...

  # Team feature configuration
  config.allow_team_creation = true
end

# config/environments/production.rb
Rails.application.configure do
  # ... existing config ...

  # Team feature configuration
  config.allow_team_creation = true
end
```

## Controller Integration

Teams are always enabled, so no need for conditional checks in ApplicationController.

### Routing
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... other routes ...

  resources :teams do
    resources :invitations, only: [:index, :new, :create, :destroy]
    member do
      patch :restore
    end
  end

  post 'teams/switch/:team_id', to: 'team_switch#update', as: :switch_team
  get 'invitations/:token', to: 'invitations#accept', as: :accept_invitation
  get 'onboarding', to: 'onboarding#show'
  post 'onboarding/create_team', to: 'onboarding#create_team'
end
```

## Policy Integration

### TeamPolicy Updates
```ruby
class TeamPolicy < ApplicationPolicy
  def create?
    Rails.configuration.allow_team_creation
  end

  # ... other methods ...
end
```

## View Integration

### Conditional UI Elements
```ruby
# In views/components
# Team switcher is always shown when user has teams
render Layout::TeamSwitcher.new

# Team creation based on configuration
if Rails.configuration.allow_team_creation
  link_to t("teams.new"), new_team_path, class: "button"
else
  span(class: "text-muted") { t("teams.creation_disabled") }
end
```

### Helper Methods (Optional)
```ruby
# app/helpers/teams_helper.rb - only if you want a helper method
module TeamsHelper
  def can_create_teams?
    Rails.configuration.allow_team_creation
  end
end
```

## Testing Configuration

### Test Helpers
```ruby
# spec/support/team_configuration_helpers.rb
module TeamConfigurationHelpers
  def with_team_creation_allowed(allowed = true)
    original = Rails.configuration.allow_team_creation
    Rails.configuration.allow_team_creation = allowed
    yield
  ensure
    Rails.configuration.allow_team_creation = original
  end
end

RSpec.configure do |config|
  config.include TeamConfigurationHelpers
end
```

### Configuration Specs
```ruby
# spec/models/team_configuration_spec.rb
RSpec.describe "Team Configuration" do
  describe "allow_team_creation" do
    it "prevents new team creation when false" do
      with_team_creation_allowed(false) do
        # Test creation blocking
      end
    end
  end
end
```

## Implementation Steps (TDD)

1. Add allow_team_creation configuration to all environment files
2. Update TeamPolicy to respect allow_team_creation
3. Update views with conditionals for team creation only
4. Add i18n for creation disabled messages
5. Test team creation configuration

## Environment Variables

### Production Setup
```bash
# .env.production
ALLOW_TEAM_CREATION=true
```

### Docker/Kamal Configuration
```yaml
# config/deploy.yml
env:
  clear:
    ALLOW_TEAM_CREATION: true
```

## Documentation

### For Developers
```ruby
# To check if user can create teams:
if policy(Team).create?
  # Show create button
end

# Or directly:
if Rails.configuration.allow_team_creation
  # Show team creation UI
end
```

### For Operations
```markdown
## Team Feature Configuration

Set this environment variable:
- `ALLOW_TEAM_CREATION`: Allow users to create teams (default: true)
```

## Key Considerations

1. **User Communication**: Clear messages when team creation is disabled
2. **Testing**: Test both enabled and disabled states for team creation
3. **UI/UX**: Gracefully handle disabled team creation in UI
