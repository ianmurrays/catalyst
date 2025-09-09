# Phase 5: Team Context & Switching

## Objective
Implement team context management with session/cookie persistence, team switching functionality, and proper authorization scoping.

## Dependencies
- Phases 1-4: Complete team infrastructure
- Existing session management

## Core Concepts

### Team Context Storage
1. **Session**: Current team ID for immediate use
2. **Cookie**: Persistent team preference (encrypted)
3. **Fallback**: First available team if no preference

### Context Flow
1. User logs in → Check cookie for last team
2. No cookie → Select first team or redirect to onboarding
3. Team switch → Update session and cookie
4. All requests → Load current team context
5. Authorization → Scope to current team

## Implementation

### ApplicationController Updates
```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_team
  
  helper_method :current_team
  
  def current_team
    @current_team ||= begin
      if session[:current_team_id]
        current_user&.teams&.find_by(id: session[:current_team_id])
      end
    end
  end
  
  private
  
  def set_current_team
    return unless logged_in?
    
    # Try session first
    if session[:current_team_id]
      @current_team = current_user.teams.find_by(id: session[:current_team_id])
    end
    
    # Try cookie if no session
    if @current_team.nil? && cookies.encrypted[:last_team_id]
      @current_team = current_user.teams.find_by(id: cookies.encrypted[:last_team_id])
    end
    
    # Default to first team
    @current_team ||= current_user.teams.first
    
    # Update session
    session[:current_team_id] = @current_team&.id
  end
  
  def require_team
    redirect_to onboarding_path unless current_team
  end
end
```

### TeamSwitchController
```ruby
class TeamSwitchController < ApplicationController
  include Secured
  
  def update
    team = current_user.teams.find(params[:team_id])
    authorize team, :switch?
    
    session[:current_team_id] = team.id
    cookies.encrypted[:last_team_id] = {
      value: team.id,
      expires: 1.year.from_now,
      httponly: true,
      secure: Rails.env.production?
    }
    
    redirect_to after_switch_path(team)
  end
  
  private
  
  def after_switch_path(team)
    # Return to previous page or team dashboard
    request.referrer || team_path(team)
  end
end
```

### Routes
```ruby
post 'teams/switch/:team_id', to: 'team_switch#update', as: :switch_team
```

## Concern Implementation

### TeamContext Concern
```ruby
module TeamContext
  extend ActiveSupport::Concern
  
  included do
    before_action :require_team
    helper_method :team_scoped_path
  end
  
  def team_scoped_path(path)
    # Helper to generate paths with team context
    # e.g., /teams/1/projects instead of /projects
  end
  
  def pundit_user
    UserContext.new(current_user, current_team)
  end
end
```

## View Helpers

### Current Team Display
```ruby
module TeamsHelper
  def current_team_name
    current_team&.name || t("teams.no_team")
  end
  
  def user_teams_for_select
    current_user.teams.map { |t| [t.name, t.id] }
  end
  
  def team_role_badge(team)
    role = current_user.membership_for(team).role
    # Return styled badge based on role
  end
end
```

## Testing Requirements

### Controller Specs
1. ApplicationController:
   - Current team selection logic
   - Cookie persistence
   - Fallback behavior

2. TeamSwitchController:
   - Successful switching
   - Authorization checks
   - Cookie updates
   - Redirect logic

### Request Specs
1. Team context flow:
   - Login with saved preference
   - Switch teams and verify context
   - Cookie persistence across sessions
   - No team handling

### Helper Specs
1. Test team context helpers
2. Test scoped path generation

## Implementation Steps (TDD)

1. Write specs for ApplicationController team methods
2. Implement current_team and set_current_team
3. Create TeamContext concern with specs
4. Write TeamSwitchController specs
5. Implement team switching
6. Add cookie handling
7. Create view helpers
8. Update existing controllers to use team context
9. Add require_team to team-scoped controllers
10. Test full integration

## Scoping Considerations

### Controllers to Update
- Projects, tasks, etc. (future features) should scope to current team
- Team management should not require current team
- Profile remains unscoped

### Model Scoping
```ruby
# Add to models that belong to teams
class Project < ApplicationRecord
  belongs_to :team
  
  # Default scope for team context
  def self.for_team(team)
    where(team: team)
  end
end
```

## Security Considerations

1. **Cookie Encryption**: Use Rails encrypted cookies
2. **Team Verification**: Always verify user has access
3. **Session Fixation**: Clear team on logout
4. **Cross-Team Leaks**: Ensure proper scoping
5. **Authorization**: Double-check team access in policies

## UI Integration Points

1. **Navbar**: Display current team name
2. **Team Switcher**: Dropdown in navbar
3. **Breadcrumbs**: Include team context
4. **URLs**: Consider team slugs in paths
5. **Empty States**: Handle no team gracefully

## Performance Optimization

1. **Eager Loading**: Preload teams for user
2. **Caching**: Cache current team in request
3. **Database Indexes**: Ensure fast lookups
4. **Session Size**: Store only team ID

## Configuration Options
```ruby
# In config/application.rb
config.team_context_timeout = 1.year
config.require_team_by_default = true
config.team_switcher_return_to_dashboard = false
```

## Key Considerations

1. **Multi-Tab Behavior**: Handle multiple browser tabs
2. **API Context**: How to handle API requests
3. **Background Jobs**: Team context in async jobs
4. **Subdomains**: Future support for team subdomains
5. **Deep Links**: Preserve team context in URLs