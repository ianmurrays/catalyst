# Phase 7: UI Components & Navigation

## Objective
Update the application UI to integrate team functionality, including navbar team switcher, team-aware navigation, and reusable team-related components.

## Dependencies
- Phases 1-6: Complete team functionality
- Ruby UI component library
- Existing navbar and layout components

## Navbar Updates

### Team Switcher Dropdown
Location: Navbar, next to the user menu (on the right)

Components needed:
- Current team display
- Dropdown trigger
- Team list with roles
- "Manage teams" link
- "Create team" link (if allowed)

### Implementation
```ruby
# app/components/layout/team_switcher.rb
class Layout::TeamSwitcher < Components::Base
  def view_template
    return unless logged_in? && current_user.teams.any?

    render RubyUI::DropdownMenu::DropdownMenu.new do
      render RubyUI::DropdownMenu::DropdownMenuTrigger.new do
        button(class: "flex items-center gap-2") do
          team_avatar
          span { current_team&.name || t("teams.select") }
          chevron_down_icon
        end
      end

      render RubyUI::DropdownMenu::DropdownMenuContent.new do
        user_teams_section
        divider
        actions_section
      end
    end
  end

  private

  def user_teams_section
    # List of teams with switch action
  end

  def actions_section
    # Manage teams and create team links
  end
end
```

### Updated Navbar
```ruby
# app/components/layout/navbar.rb updates
class Layout::Navbar < Components::Base
  def view_template
    nav(class: "navbar") do
      brand_section
      render Layout::TeamSwitcher.new  # New component
      user_section
    end
  end
end
```

## Reusable Components

### Team Components Directory
```
app/components/teams/
├── team_avatar.rb       # Team icon/initial
├── team_card.rb         # Card for team lists
├── team_switcher.rb     # Dropdown switcher
├── member_avatar.rb     # Member display
├── member_list.rb       # Team members list
├── role_badge.rb        # Role indicator
├── invitation_link.rb   # Copyable invite link
└── empty_state.rb       # No teams message
```

### Key Components

1. **TeamAvatar**
   - Display team initial or icon
   - Consistent sizing variants
   - Fallback for no name

2. **RoleBadge**
   - Styled role indicator
   - Color coding by role
   - Tooltips for permissions

3. **MemberList**
   - Tabular or card layout
   - Shows avatar, name, role
   - Actions based on permissions

4. **InvitationLink**
   - Displays shareable URL
   - Copy button with feedback
   - Expiration indicator
   - QR code option

## Page Updates

### Home Page
- Show team context if logged in
- Quick team switcher
- Recent team activity

### Profile Page
- List user's teams
- Quick switch option
- Leave team functionality

### Application Layout
- Include team context in title
- Breadcrumbs with team

## Ruby UI Integration

### Using Ruby UI Components
```ruby
# Team card with Ruby UI
render RubyUI::Card::Card.new(class: "team-card") do
  render RubyUI::Card::CardHeader.new do
    div(class: "flex justify-between") do
      team_name_and_role
      team_actions_dropdown
    end
  end

  render RubyUI::Card::CardContent.new do
    team_statistics
  end

  render RubyUI::Card::CardFooter.new do
    last_activity_info
  end
end
```

### Dropdown Patterns
```ruby
# Consistent dropdown usage
render RubyUI::DropdownMenu::DropdownMenu.new do
  # Trigger and content
end
```

## Testing Requirements

### Component Specs
1. TeamSwitcher:
   - Shows current team
   - Lists all user teams
   - Handles no teams
   - Respects permissions

2. TeamAvatar:
   - Generates correct initials
   - Falls back appropriately

3. RoleBadge:
   - Correct styling per role
   - Proper text

### Integration Tests
1. Navbar functionality:
   - Team switching works
   - Updates current context
   - Redirects appropriately

## Implementation Steps (TDD)

1. Create component specs
2. Build team avatar component
3. Build role badge component
4. Create team switcher specs
5. Implement team switcher
6. Update navbar with switcher
7. Create member list component
8. Build invitation link component
9. Style with Tailwind CSS
10. Test responsive behavior

## Styling Guidelines

### Team Colors
```css
/* Role-based colors */
.role-owner { @apply bg-purple-100 text-purple-800; }
.role-admin { @apply bg-blue-100 text-blue-800; }
.role-member { @apply bg-green-100 text-green-800; }
.role-viewer { @apply bg-gray-100 text-gray-800; }
```

### Component Styling
- Consistent spacing and sizing
- Hover states for interactive elements
- Focus indicators for accessibility
- Dark mode support

## JavaScript Enhancements

### Stimulus Controllers
```javascript
// app/javascript/controllers/team_switcher_controller.js
export default class extends Controller {
  connect() {
    // Initialize dropdown behavior
  }

  switch(event) {
    // Handle team switching
    const teamId = event.currentTarget.dataset.teamId
    // Post to switch endpoint
  }
}

// app/javascript/controllers/clipboard_controller.js
export default class extends Controller {
  copy() {
    navigator.clipboard.writeText(this.data.get("text"))
    this.showCopiedFeedback()
  }

  showCopiedFeedback() {
    // Visual feedback
  }
}
```

## I18n Updates
```yaml
en:
  teams:
    switcher:
      current: "Current Team"
      switch_to: "Switch to %{team}"
      manage_teams: "Manage Teams"
      create_team: "Create New Team"
      no_teams: "No teams yet"
    roles:
      owner: "Owner"
      admin: "Admin"
      member: "Member"
      viewer: "Viewer"
    avatar:
      fallback: "T"  # Default for no name
```

## Accessibility Considerations

1. **ARIA Labels**: Proper labeling for screen readers
2. **Keyboard Navigation**: Full keyboard support
3. **Focus Management**: Proper focus states
4. **Color Contrast**: WCAG AA compliance
5. **Screen Reader Announcements**: For dynamic changes

## Performance Optimization

1. **Lazy Loading**: Load team lists on demand
2. **Caching**: Cache team switcher content
3. **Turbo Frames**: Use for partial updates
4. **Preloading**: Eager load associations

## Mobile Responsiveness

1. **Touch Targets**: Minimum 44x44px
2. **Responsive Layouts**: Stack on mobile
3. **Bottom Sheets**: Mobile-friendly dropdowns
4. **Swipe Gestures**: For team switching
5. **Condensed Views**: Show essential info only

## Future Enhancements

1. **Team Notifications**: Badge for activity
2. **Quick Actions**: Inline team actions
3. **Search**: Find teams quickly
4. **Favorites**: Pin frequent teams
5. **Recent Teams**: Quick access list
