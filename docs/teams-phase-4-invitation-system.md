# Phase 4: Invitation System

## Objective
Implement a shareable invitation link system that allows team owners/admins to invite new members with specified roles and configurable expiration times.

## Dependencies
- Phase 1-3: Teams, policies, and management UI
- Existing authentication system

## Core Features

### Invitation Flow
1. Admin/owner creates invitation with role and expiration
2. System generates unique, secure token
3. Invitation URL can be shared (not sent by system)
4. Recipient visits URL and authenticates
5. System adds them to team with specified role
6. Invitation is marked as used

## Controllers Implementation

### InvitationsController
```ruby
class InvitationsController < ApplicationController
  include Secured
  before_action :set_team
  before_action :set_invitation, only: [:show, :destroy]
  skip_before_action :require_authentication, only: [:accept]
  
  def index
    # List team invitations (admin/owner only)
  end
  
  def new
    # Form to create invitation
  end
  
  def create
    # Generate invitation with token
  end
  
  def accept
    # Handle invitation acceptance (stores in session if not logged in)
  end
  
  def destroy
    # Revoke unused invitation
  end
end
```

### Routes Configuration
```ruby
resources :teams do
  resources :invitations, only: [:index, :new, :create, :destroy]
end

# Public invitation acceptance route
get 'invitations/:token', to: 'invitations#accept', as: :accept_invitation
```

## Views Implementation

### Invitations Views
```
app/views/invitations/
├── index.rb          # List of team invitations
├── new.rb            # Create invitation form
└── accept.rb         # Acceptance confirmation page

app/components/invitations/
├── invitation_row.rb      # Table row for invitation
├── invitation_form.rb     # Form component
├── expiration_select.rb   # Expiration options
└── share_link.rb         # Copyable invitation link
```

### Key Components

1. **Invitations::New**
   - Role selection (based on current user's role)
   - Generate button
   - Display generated link with copy button

2. **Invitations::Index**
   - Table of active invitations
   - Shows: role, created by, status
   - Revoke button for each
   - Filter: active, used

3. **Share Link Component**
   - Displays full invitation URL
   - Copy to clipboard button
   - QR code generation (optional)

## Service Objects

### InvitationService
```ruby
class InvitationService
  def self.create(team:, role:, created_by:)
    # Generate secure token
    # Create invitation record (never expires)
    # Return invitation with full URL
  end
  
  def self.accept(token:, user:)
    # Find invitation by token
    # Validate not used
    # Create membership
    # Mark invitation as used
  end
end
```

## Testing Requirements

### Controller Specs
1. InvitationsController:
   - Authorization for create/index/destroy
   - Token generation uniqueness
   - Acceptance flow with/without auth
   - Session storage for unauthenticated users

### Service Specs
1. InvitationService:
   - Token generation and uniqueness
   - Acceptance validation
   - Error handling

### Integration Tests
1. Full invitation flow:
   - Create invitation
   - Copy link
   - Visit as new user
   - Redirect to auth
   - Auto-join after auth
   - Verify membership created

## Implementation Steps (TDD)

1. Write InvitationService specs
2. Implement InvitationService
3. Write controller specs
4. Implement InvitationsController
5. Add routes
6. Write view component specs
7. Create Phlex views
8. Add JavaScript for clipboard copying
9. Add i18n translations
10. Style with Tailwind CSS

## Security Considerations

1. **Token Generation**: Use `SecureRandom.urlsafe_base64(32)`
2. **Token Storage**: Store hashed version in database
3. **Rate Limiting**: Limit invitation creation per team
4. **Permission Checks**: Can't invite with higher role than self
5. **Audit Trail**: Log invitation creation and usage

## JavaScript Enhancement

### Clipboard Copy
```javascript
// Stimulus controller for copy button
export default class extends Controller {
  copy() {
    navigator.clipboard.writeText(this.data.get("text"))
    // Show success feedback
  }
}
```

## I18n Structure
```yaml
en:
  invitations:
    new:
      title: "Invite Team Members"
      role_label: "Role"
      generate_button: "Generate Invitation Link"
    index:
      title: "Team Invitations"
      active_tab: "Active"
      used_tab: "Used"
      revoke_confirm: "Are you sure you want to revoke this invitation?"
    flash:
      created: "Invitation created successfully"
      accepted: "You've joined the team!"
      already_member: "You're already a member of this team"
```

## Key Considerations

1. **URL Structure**: Use subdomain or path for team context
2. **Mobile Experience**: Easy sharing on mobile devices
3. **Invitation Limits**: Consider max active invitations
4. **Analytics**: Track invitation usage and conversion
5. **Email Integration**: Future: email invitation option
6. **Bulk Invitations**: Future: invite multiple people at once

## Integration Points

- Update team show page to include invitation section
- Add invitation count to team cards
- Consider dashboard widget for pending invitations
- Integrate with onboarding flow for new users