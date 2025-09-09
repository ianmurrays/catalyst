# Phase 6: Onboarding Flow

## Objective
Implement a seamless onboarding experience for new users, handling both team creation and invitation acceptance flows, with proper redirects and state management.

## Dependencies
- Phases 1-5: Complete team system with invitations
- Auth0 authentication flow

## User Flows

### Flow 1: New User Without Invitation
1. User signs up/logs in via Auth0
2. System checks for existing teams
3. No teams → Redirect to onboarding
4. Prompt to create first team
5. Create team (user becomes owner)
6. Redirect to team dashboard

### Flow 2: New User With Invitation
1. User clicks invitation link
2. Token stored in session
3. Redirect to Auth0 login
4. After auth, check for invitation token
5. Accept invitation automatically
6. Redirect to team dashboard

### Flow 3: Existing User With Invitation
1. User clicks invitation link
2. Already authenticated → Check invitation validity
3. Accept invitation directly (no Auth0 redirect)
4. Add user to team with specified role
5. Redirect to team dashboard

### Flow 4: Existing User Without Teams
1. User logs in
2. No teams found
3. Redirect to onboarding
4. Show "create team" or "ask for invitation"

### Flow 5: Team Creation Disabled
1. User has no teams
2. Team creation disabled in config
3. Show "waiting for invitation" page
4. Provide instructions to contact admin

## Controllers Implementation

### OnboardingController
```ruby
class OnboardingController < ApplicationController
  include AuthProvider
  include Secured
  skip_before_action :require_team
  
  def show
    # Check if user already has teams
    redirect_to teams_path if current_user.teams.any?
    
    # Check configuration
    @can_create_teams = Rails.configuration.allow_team_creation
  end
  
  def create_team
    # Handle team creation from onboarding
    unless Rails.configuration.allow_team_creation
      redirect_to onboarding_path, alert: t("onboarding.team_creation_disabled")
      return
    end
    
    # Create team logic
  end
end
```

### Auth0Controller Updates
```ruby
# In auth0_controller.rb callback action
def callback
  # Existing auth logic...
  
  # Check for pending invitation
  if session[:invitation_token].present?
    handle_invitation_acceptance
  elsif current_user.teams.empty?
    redirect_to onboarding_path
  else
    redirect_to session[:return_to] || root_path
  end
end

private

def handle_invitation_acceptance
  result = InvitationService.accept(
    token: session[:invitation_token],
    user: current_user
  )
  
  session.delete(:invitation_token)
  
  if result.success?
    redirect_to team_path(result.team)
  else
    redirect_to onboarding_path, alert: result.error
  end
end
```

### InvitationsController Updates
```ruby
# Update accept action for non-authenticated users
def accept
  invitation = Invitation.find_by_token(params[:token])
  
  unless invitation&.valid_for_use?
    redirect_to root_path, alert: t("invitations.invalid")
    return
  end
  
  if logged_in?
    # Direct acceptance
    result = InvitationService.accept(token: params[:token], user: current_user)
    # Handle result...
  else
    # Store token and redirect to auth
    session[:invitation_token] = params[:token]
    redirect_to "/auth/auth0", allow_other_host: true
  end
end
```

## Views Implementation

### Onboarding Views
```
app/views/onboarding/
├── show.rb              # Main onboarding page
├── create_team.rb       # Team creation form
└── waiting_invitation.rb # When creation disabled

app/components/onboarding/
├── welcome_message.rb   # Personalized welcome
├── team_prompt.rb       # Create team CTA
└── invitation_wait.rb   # Waiting state
```

### Key Views

1. **Onboarding::Show**
   - Welcome message with user name
   - Explanation of teams
   - "Create Your First Team" button (if allowed)
   - "I have an invitation" link
   - Waiting message (if creation disabled)

2. **Onboarding::CreateTeam**
   - Simplified team creation form
   - Team name input
   - Purpose/description (optional)
   - Create button
   - Skip option (if applicable)

3. **Onboarding::WaitingInvitation**
   - Message about needing invitation
   - Contact information
   - Check again button
   - Logout option

## Testing Requirements

### Controller Specs
1. OnboardingController:
   - Redirect when user has teams
   - Show correct view based on config
   - Team creation authorization

2. Auth0Controller updates:
   - Invitation token handling
   - Onboarding redirect logic
   - Session cleanup

### Integration Specs
1. Complete flows:
   - New user → onboarding → team creation
   - Invitation click → auth → auto-join
   - Config disabled → waiting page

### Feature Specs
1. User experience tests:
   - Smooth flow without confusion
   - Clear messaging
   - Proper redirects

## Implementation Steps (TDD)

1. Update Auth0Controller callback specs
2. Implement invitation check in callback
3. Create OnboardingController specs
4. Implement onboarding controller
5. Create view component specs
6. Build Phlex views
7. Add routes for onboarding
8. Update application flow
9. Add i18n translations
10. Test all user flows

## Routes Configuration
```ruby
# Onboarding routes
get 'onboarding', to: 'onboarding#show'
post 'onboarding/create_team', to: 'onboarding#create_team'

# Update root route logic
root to: 'pages#home'
# Or conditional root based on auth status
```

## I18n Structure
```yaml
en:
  onboarding:
    welcome:
      title: "Welcome to %{app_name}, %{name}!"
      subtitle: "Let's get you set up with a team"
    create_team:
      heading: "Create Your First Team"
      description: "Teams help you collaborate and organize your work"
      button: "Create Team"
      skip: "I'll do this later"
    waiting:
      title: "Waiting for Invitation"
      message: "You need to be invited to a team to continue"
      contact: "Please contact your administrator"
      check_again: "Check Again"
    flash:
      team_created: "Team created! Welcome aboard!"
      invitation_accepted: "You've joined the team!"
      team_creation_disabled: "Team creation is currently disabled"
```

## State Management

### Session Keys
- `:invitation_token` - Pending invitation
- `:onboarding_completed` - Track completion
- `:return_to` - Original destination

### Cookie Usage
- Remember onboarding preferences
- Skip onboarding for returning users

## UI/UX Considerations

1. **Progressive Disclosure**: Don't overwhelm new users
2. **Clear CTAs**: One primary action per screen
3. **Exit Options**: Allow skipping if appropriate
4. **Loading States**: Show progress during team creation
5. **Error Handling**: Clear messages for failures
6. **Mobile First**: Ensure works on small screens

## Configuration Integration
```ruby
# Check in controllers and views
if Rails.configuration.allow_team_creation
  # Show create option
else
  # Show waiting state
end
```

## Edge Cases

1. **Expired Invitations**: Clear error messaging
2. **Already Member**: Handle gracefully
3. **Multiple Invitations**: Use most recent
4. **Race Conditions**: User creates team while accepting
5. **Back Button**: Maintain proper state

## Future Enhancements

1. **Team Templates**: Pre-configured team types
2. **Bulk Invites**: Invite multiple users during creation
3. **Import Members**: From CSV or other systems
4. **Demo Mode**: Try features without creating team
5. **Guided Tour**: Interactive onboarding