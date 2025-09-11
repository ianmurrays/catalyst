# TeamContext Integration Guide

## Overview

The `TeamContext` concern provides team-scoped functionality for controllers that manage team-specific resources. It builds on the existing authentication system and provides consistent team context management across the application.

## When to Include TeamContext

Include `TeamContext` concern in controllers that:

- **Manage resources that belong to teams** - Controllers for projects, tasks, documents, etc.
- **Need team-scoped authorization** - Controllers that require team membership checks
- **Display team-specific data** - Controllers that show data filtered by current team
- **Require team context for navigation** - Controllers that need team-aware breadcrumbs or paths

### Examples of Good Candidates

```ruby
# Future team-scoped controllers
class ProjectsController < ApplicationController
  include TeamContext  # ✅ Projects belong to teams
end

class TasksController < ApplicationController  
  include TeamContext  # ✅ Tasks belong to projects which belong to teams
end

class DashboardController < ApplicationController
  include TeamContext  # ✅ Dashboard shows team-specific data
end
```

## When NOT to Include TeamContext

Do NOT include `TeamContext` in controllers that:

- **Manage teams themselves** - `TeamsController` has its own team management logic
- **Handle authentication** - `Auth0Controller` is for login/logout only
- **Manage user profiles** - `ProfileController` is user-scoped, not team-scoped
- **Are purely administrative** - Global admin interfaces that work across all teams
- **Already inherit team context** - Controllers that inherit from ApplicationController get basic team functionality

### Examples to Avoid

```ruby
class TeamsController < ApplicationController
  # ❌ DON'T include TeamContext - manages teams themselves
end

class Auth0Controller < ApplicationController
  # ❌ DON'T include TeamContext - handles authentication
end

class ProfileController < ApplicationController
  # ❌ DON'T include TeamContext - user-scoped, not team-scoped
end

class AdminController < ApplicationController
  # ❌ DON'T include TeamContext - global admin interface
end
```

## Integration Pattern

### Basic Integration

```ruby
class ProjectsController < ApplicationController
  include TeamContext  # This adds team requirement and helpers

  def index
    @projects = scope_to_current_team(Project.all)
  end

  def show
    @project = scope_to_current_team(Project).find(params[:id])
  end

  def new
    @project = build_for_current_team(Project)
  end

  def create
    @project = build_for_current_team(Project, project_params)
    
    if @project.save
      redirect_to team_scoped_path("/projects/#{@project.id}")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
```

### With Authorization

```ruby
class ProjectsController < ApplicationController
  include TeamContext
  include Secured  # Require authentication

  def update
    @project = scope_to_current_team(Project).find(params[:id])
    authorize @project  # Uses UserContext from TeamContext

    if @project.update(project_params)
      redirect_to team_scoped_path("/projects/#{@project.id}")
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

## Available Methods

### Team Access Control

- `current_user_role` - Returns user's role in current team (`'owner'`, `'admin'`, `'member'`, `'viewer'`)
- `can_manage_team?` - Returns `true` if user is owner or admin
- `can_edit_team_settings?` - Returns `true` if user is owner

### Resource Scoping

- `scope_to_current_team(relation)` - Scopes ActiveRecord relation to current team
- `build_for_current_team(model_class, attributes)` - Builds model through team association

### Path Helpers

- `team_scoped_path(path)` - Generates team-scoped paths (e.g., `/teams/1/projects`)
- `team_scoped_url_for(options)` - URL generation with team context
- `team_breadcrumb_items` - Returns breadcrumb items with team navigation

### Pundit Integration

- `pundit_user` - Returns `UserContext` with current user and team for policy authorization

## Filter Behavior

`TeamContext` adds a `before_action :require_team` filter that:

1. **Checks for current team** - Redirects to teams page if no team selected
2. **Runs after authentication** - Requires user to be logged in first
3. **Sets alert message** - Provides user feedback when team selection required

### Filter Ordering

When combining with other concerns:

```ruby
class ResourceController < ApplicationController
  include AuthProvider   # 1. Provides authentication methods
  include Secured       # 2. Requires login (redirects to /auth/auth0)
  include TeamContext   # 3. Requires team (redirects to /teams)
  
  # Filters run in order: authentication check → team check → controller action
end
```

## Testing TeamContext Controllers

### Controller Specs

```ruby
RSpec.describe ProjectsController, type: :controller do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

  before do
    login_as(user)
    # Set current team for testing
    session[:current_team_id] = team.id
  end

  describe "GET #index" do
    it "scopes projects to current team" do
      team_project = create(:project, team: team)
      other_project = create(:project, team: create(:team))

      get :index

      expect(assigns(:projects)).to include(team_project)
      expect(assigns(:projects)).not_to include(other_project)
    end
  end

  describe "team context requirements" do
    before { session[:current_team_id] = nil }

    it "redirects when no team selected" do
      get :index
      expect(response).to redirect_to(teams_path)
    end
  end
end
```

### Request Specs

```ruby
RSpec.describe "Projects", type: :request do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }

  before do
    create(:membership, user: user, team: team)
    login_as(user)
    session[:current_team_id] = team.id
  end

  describe "GET /projects" do
    it "shows team projects" do
      get "/projects"
      expect(response).to have_http_status(:success)
    end
  end
end
```

## Compatibility Notes

### With Existing Concerns

`TeamContext` is designed to work with:

- ✅ `AuthProvider` - Uses authentication methods
- ✅ `Secured` - Runs after authentication check
- ✅ `Pundit::Authorization` - Provides `UserContext` for policies

### With ApplicationController

`ApplicationController` already has team context functionality built-in for global team management. `TeamContext` is for controllers that need team-scoped resource management.

### Future Migration

When migrating ApplicationController's team logic to use TeamContext:

1. **Extract common methods** to TeamContext concern
2. **Update ApplicationController** to include TeamContext
3. **Remove duplicate code** from ApplicationController
4. **Update tests** to ensure compatibility

## Error Handling

### Missing Team Context

If `current_team` is `nil`, `TeamContext` will:

1. Redirect to `teams_path`
2. Set flash alert: `t("teams.errors.no_team_selected")`
3. Halt the request cycle

### Authorization Failures

For authorization errors, rely on Pundit's built-in error handling:

```ruby
# In ApplicationController
rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

def user_not_authorized
  flash[:alert] = t("pundit.not_authorized")
  redirect_to(request.referrer || root_path)
end
```

## Migration Checklist

When adding TeamContext to a new controller:

- [ ] Verify controller manages team-scoped resources
- [ ] Include `TeamContext` after authentication concerns
- [ ] Update resource queries to use scoping methods
- [ ] Use team-scoped path helpers for redirects
- [ ] Add controller tests for team requirements
- [ ] Update routes if needed for team-scoped paths
- [ ] Test authorization with different team roles

## Examples by Use Case

### Resource Controller (CRUD)

```ruby
class ProjectsController < ApplicationController
  include TeamContext

  def index
    @projects = scope_to_current_team(Project.includes(:team))
  end

  def show
    @project = scope_to_current_team(Project).find(params[:id])
    @breadcrumbs = team_breadcrumb_items + [
      { name: @project.name, path: team_scoped_path("/projects/#{@project.id}") }
    ]
  end
end
```

### Dashboard Controller

```ruby
class DashboardController < ApplicationController
  include TeamContext

  def show
    @recent_projects = scope_to_current_team(Project).recent.limit(5)
    @team_stats = calculate_team_stats
    @breadcrumbs = team_breadcrumb_items + [
      { name: t("navigation.dashboard"), path: team_scoped_path("/dashboard") }
    ]
  end

  private

  def calculate_team_stats
    {
      projects_count: scope_to_current_team(Project).count,
      active_members: current_team.users.count,
      # ... other stats
    }
  end
end
```

### Nested Resource Controller

```ruby
class Project::TasksController < ApplicationController
  include TeamContext

  before_action :set_project

  def index
    @tasks = @project.tasks.includes(:assignee)
  end

  def create
    @task = @project.tasks.build(task_params)
    @task.created_by = current_user

    if @task.save
      redirect_to team_scoped_path("/projects/#{@project.id}/tasks")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = scope_to_current_team(Project).find(params[:project_id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :assignee_id, :due_date)
  end
end
```

---

This guide provides the foundation for implementing team-scoped controllers using the `TeamContext` concern. Follow these patterns to ensure consistent team context management across your application.