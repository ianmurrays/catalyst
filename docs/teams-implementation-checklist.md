# Teams Feature Implementation Checklist

This checklist tracks the progress of implementing the teams feature across all phases. Check off items as they are completed.

## Phase 1: Database Schema & Models
- [x] Create teams table migration
  - [x] id, name, slug, deleted_at, created_at, updated_at
  - [x] Add unique index on slug
- [x] Create memberships table migration
  - [x] id, user_id, team_id, role, created_at, updated_at
  - [x] Add compound index on [user_id, team_id]
- [x] Create invitations table migration
  - [x] id, team_id, token, role, expires_at, created_by_id, used_at, used_by_id
  - [x] Add unique index on token
- [x] Create Team model with validations and associations
- [x] Create Membership model with role enum
- [x] Create Invitation model with token generation
- [x] Write model specs for all three models
- [x] Run migrations and verify schema

## Phase 2: Authorization Setup
- [x] Add pundit gem to Gemfile
- [x] Run bundle install
- [x] Include Pundit in ApplicationController
- [x] Generate ApplicationPolicy
- [x] Create TeamPolicy with basic rules
- [x] Create MembershipPolicy
- [x] Create InvitationPolicy
- [x] Update Secured concern to handle team context
- [x] Write policy specs
- [x] Add pundit_user method to ApplicationController

## Phase 3: Team Management
- [ ] Create TeamsController
  - [ ] index, show, new, create, edit, update, destroy actions
  - [ ] Soft delete implementation
- [ ] Create team views using Phlex
  - [ ] Teams::Index view
  - [ ] Teams::Show view
  - [ ] Teams::New view
  - [ ] Teams::Edit view
  - [ ] Teams::Form component
- [ ] Add team routes
- [ ] Write controller specs
- [ ] Write request specs
- [ ] Add i18n translations

## Phase 4: Invitation System
- [ ] Create InvitationsController
  - [ ] new, create, accept actions
- [ ] Create invitation views
  - [ ] Invitations::New view
  - [ ] Invitations::Accept view
- [ ] Add invitation routes with token parameter
- [ ] Implement invitation acceptance flow
- [ ] Add invitation expiration options (1 hour, 1 day, 3 days, 1 week, never)
- [ ] Create invitation link generation service
- [ ] Write controller and service specs
- [ ] Add i18n translations

## Phase 5: Team Context & Switching
- [ ] Add current_team to ApplicationController
- [ ] Implement team selection storage (session + cookie)
- [ ] Create TeamSelector concern
- [ ] Add set_current_team before_action
- [ ] Create team switching endpoint
- [ ] Update TeamPolicy for switching permissions
- [ ] Write specs for team context
- [ ] Test cookie persistence across sessions

## Phase 6: Onboarding Flow
- [ ] Create OnboardingController
- [ ] Create team creation prompt view
- [ ] Create no-team state view
- [ ] Add onboarding routes
- [ ] Implement post-login redirect logic
- [ ] Handle invitation token in session
- [ ] Add invitation acceptance in auth callback
- [ ] Write onboarding specs
- [ ] Test various user flows

## Phase 7: UI Components & Navigation
- [ ] Update navbar with team switcher dropdown
- [ ] Create TeamSwitcher component
- [ ] Add current team display
- [ ] Create team avatar/icon component
- [ ] Update application layout
- [ ] Add team context to necessary views
- [ ] Style with Tailwind CSS
- [ ] Write component specs
- [ ] Test responsive behavior

## Phase 8: Configuration & Settings
- [ ] Add team configuration to environment files
  - [ ] config.teams_enabled (default: true)
  - [ ] config.allow_team_creation (default: true)
- [ ] Update ApplicationController to check settings
- [ ] Conditionally show/hide team creation
- [ ] Add configuration checks to policies
- [ ] Write configuration specs
- [ ] Document configuration options

## Phase 9: Testing & Quality Assurance
- [ ] Run full test suite
- [ ] Fix any failing tests
- [ ] Add integration tests for complete flows
  - [ ] New user with team creation
  - [ ] New user with invitation
  - [ ] Existing user switching teams
  - [ ] Team deletion flow
- [ ] Run Rubocop and fix issues
- [ ] Test in different environments
- [ ] Performance testing with multiple teams
- [ ] Security review of policies
- [ ] Documentation review

## Final Steps
- [ ] Code review
- [ ] Update CLAUDE.md with teams documentation
- [ ] Create user-facing documentation
- [ ] Deploy to staging
- [ ] User acceptance testing
- [ ] Deploy to production