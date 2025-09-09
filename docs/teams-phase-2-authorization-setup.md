# Phase 2: Authorization Setup with Pundit

## Objective
Install and configure Pundit for authorization, create policies for teams, memberships, and invitations, and integrate with the existing authentication system.

## Dependencies
- Phase 1 completed (models created)
- Existing AuthProvider and Secured concerns

## Pundit Installation

1. Add to Gemfile: `gem 'pundit'`
2. Run `bundle install`
3. Include Pundit in ApplicationController
4. Run `rails g pundit:install` to generate ApplicationPolicy

## Core Configuration

### ApplicationController Updates
```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  # Define pundit_user to include current team context
  def pundit_user
    UserContext.new(current_user, current_team)
  end
  
  # Handle authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    flash[:alert] = t("pundit.not_authorized")
    redirect_to(request.referrer || root_path)
  end
end
```

### UserContext Struct
Create a UserContext to pass both user and team to policies:
```ruby
UserContext = Struct.new(:user, :team) do
  def team_role
    return nil unless user && team
    user.memberships.find_by(team: team)&.role
  end
end
```

## Policy Implementations

### ApplicationPolicy
Base policy with common patterns:
- Helper methods for checking team roles
- Common scopes for team-based filtering

### TeamPolicy
Permissions:
- `index?`: logged in users can see their teams
- `show?`: team members can view
- `create?`: check Rails.configuration.allow_team_creation
- `update?`: owners and admins only
- `destroy?`: owners only
- `switch?`: team members only

### MembershipPolicy
Permissions:
- `index?`: team members can see member list
- `create?`: owners and admins can invite
- `update?`: owners and admins can change roles (with restrictions)
- `destroy?`: owners and admins can remove members

### InvitationPolicy
Permissions:
- `index?`: owners and admins can see invitations
- `create?`: owners and admins can create
- `destroy?`: invitation creator or team owners/admins
- `accept?`: any logged in user with valid token

## Testing Requirements

### Policy Specs
Use RSpec and create comprehensive policy specs:

1. TeamPolicy specs:
   - Test each action for different roles
   - Test team creation permission (respects allow_team_creation)
   - Test scope filtering

2. MembershipPolicy specs:
   - Role change restrictions (can't demote last owner)
   - Self-modification restrictions
   - Scope tests

3. InvitationPolicy specs:
   - Token-based access for accept
   - Creator permissions
   - Expiration handling

### Test Helpers
Create policy test helpers:
```ruby
# spec/support/pundit_helpers.rb
module PunditHelpers
  def permit_action(action, user:, record:, team: nil)
    context = UserContext.new(user, team)
    policy = described_class.new(context, record)
    expect(policy.send("#{action}?")).to be true
  end
  
  def forbid_action(action, user:, record:, team: nil)
    context = UserContext.new(user, team)
    policy = described_class.new(context, record)
    expect(policy.send("#{action}?")).to be false
  end
end
```

## Implementation Steps (TDD)

1. Add pundit gem and bundle install
2. Generate pundit install
3. Write UserContext struct specs
4. Write ApplicationPolicy base specs
5. Write TeamPolicy specs (failing)
6. Implement TeamPolicy to pass specs
7. Repeat for MembershipPolicy and InvitationPolicy
8. Update ApplicationController with Pundit
9. Add authorization to existing controllers
10. Run full test suite

## Key Considerations

1. **Role Hierarchy**: Define clear role permissions (owner > admin > member > viewer)
2. **Last Owner Protection**: Prevent removing/demoting the last owner
3. **Self-Service Restrictions**: Users shouldn't demote themselves from owner
4. **Scope Performance**: Use efficient queries in policy scopes
5. **Error Messages**: Provide clear, i18n-ized authorization error messages
6. **Policy Caching**: Consider caching expensive authorization checks
7. **Audit Trail**: Log authorization failures for security monitoring

## Integration Points

- Update Secured concern to work with team context
- Add `authorize` calls to all team-related controller actions
- Update views to use policy checks for conditional rendering
- Consider creating view helpers for common policy checks

## Configuration Integration

The TeamPolicy should respect configuration settings:
- Check `Rails.configuration.allow_team_creation` in create? method