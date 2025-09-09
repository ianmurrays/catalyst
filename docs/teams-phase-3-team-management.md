# Phase 3: Team Management Controllers & Views

## Objective
Implement full CRUD operations for teams with controllers, Phlex views, and proper authorization using Pundit policies.

## Dependencies
- Phase 1: Models created
- Phase 2: Pundit policies configured

## Controllers Implementation

### TeamsController
Actions to implement:
- `index` - List user's teams
- `show` - Display team details and members
- `new` - Form for creating a team
- `create` - Create team and add creator as owner
- `edit` - Form for editing team details
- `update` - Update team information
- `destroy` - Soft delete team

Key features:
- Include Secured concern for authentication
- Authorize all actions with Pundit
- Handle slug generation and uniqueness
- Soft deletion implementation
- Strong parameters for team attributes

### Routes Configuration
```ruby
resources :teams do
  member do
    patch :restore  # for undeleting
  end
end
```

## Phlex Views Structure

### Views Hierarchy
```
app/views/teams/
├── index.rb          # List of user's teams
├── show.rb           # Team details page
├── new.rb            # New team form
└── edit.rb           # Edit team form

app/components/teams/
├── team_card.rb      # Reusable team card
├── team_form.rb      # Shared form component
├── member_list.rb    # Members display
└── empty_state.rb    # No teams message
```

### Key View Components

1. **Teams::Index**
   - Display list of teams
   - Show user's role in each team
   - Link to create new team (if allowed)
   - Empty state when no teams

2. **Teams::Show**
   - Team information display
   - Members list with roles
   - Invitation section (for admins/owners)
   - Edit/Delete buttons (based on permissions)
   - Activity/audit log section

3. **Teams::TeamForm** (component)
   - Name input with slug preview
   - Validation error display
   - Cancel and submit buttons
   - Use Ruby UI components
   - Shared between new and edit views

## Testing Requirements

### Controller Specs
1. TeamsController specs:
   - Authentication required for all actions
   - Authorization checks for each action
   - Successful CRUD operations
   - Error handling (validation failures)
   - Soft delete behavior
   - Redirect logic

### Request Specs
1. Full flow integration tests:
   - Creating a team makes user the owner
   - Editing team requires proper role
   - Deleting team soft deletes
   - Non-members can't access team

### View/Component Specs
1. Test Phlex components:
   - Proper rendering of team information
   - Conditional display based on permissions
   - Form rendering and validation display
   - Empty states

## Implementation Steps (TDD)

1. Write controller specs (failing)
2. Generate TeamsController
3. Add routes
4. Implement controller actions minimally
5. Write view component specs
6. Create Phlex view classes
7. Create reusable components
8. Add i18n translations
9. Style with Tailwind CSS
10. Run all specs and fix failures

## I18n Structure
```yaml
en:
  teams:
    index:
      title: "My Teams"
      new_team: "Create New Team"
      empty_state: "You don't belong to any teams yet"
    show:
      members: "Team Members"
      settings: "Team Settings"
      invite_members: "Invite Members"
    form:
      name_label: "Team Name"
      name_placeholder: "Enter team name"
      slug_label: "URL Slug"
      slug_help: "This will be used in URLs"
    flash:
      created: "Team created successfully"
      updated: "Team updated successfully"
      deleted: "Team deleted successfully"
      not_authorized: "You don't have permission to do that"
```

## Key Considerations

1. **Slug Generation**: Auto-generate from name, ensure uniqueness
2. **Form Validation**: Client and server-side validation
3. **Empty States**: Helpful messaging when no teams exist
4. **Loading States**: Consider turbo frames for async loading
5. **Responsive Design**: Mobile-first approach
6. **Accessibility**: Proper ARIA labels and keyboard navigation
7. **Performance**: Eager load associations to avoid N+1
8. **Activity Tracking**: Show recent team activity using audited gem

## UI/UX Guidelines

1. Use Ruby UI components consistently
2. Follow existing app styling patterns
3. Card-based layout for team listing
4. Clear visual hierarchy
5. Prominent CTA for team creation
6. Inline editing where appropriate
7. Confirmation dialogs for destructive actions

## Integration Points

- Link from user profile to teams
- Update navbar to show current team
- Add team switcher preparation
- Consider breadcrumbs for navigation
- Integrate with notification system (future)
