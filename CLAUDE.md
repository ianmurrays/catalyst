# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Catalyst" - a Rails 8 application template built with modern tooling and Ruby UI components. It serves as a foundation for Rails applications with pre-configured authentication (Auth0), UI components (Ruby UI with Phlex), and modern CSS (Tailwind 4).

### Key Technologies

- **Rails 8** with modern asset pipeline (Propshaft)
- **Ruby UI** components built with Phlex for view layer abstraction
- **Tailwind CSS 4** for styling with `tailwind_merge` for class composition
- **Auth0** for authentication with CSRF protection
- **RSpec** for testing with FactoryBot and Shoulda Matchers
- **Solid Cache/Queue/Cable** for Rails background jobs and caching
- **Kamal** for Docker-based deployment

## Development Commands

### Essential Commands
```bash
bin/rails server                    # Start development server
bin/dev                            # Start development with asset watching
bin/rails console                  # Rails console
bin/setup                          # Initial project setup
bundle exec rspec                  # Run all tests
bin/rubocop                        # Run linter (omakase style)
bin/rename MyNewApp                # Rename application
```

### Detailed Guides
- **Testing**: See @.claude/guides/testing-guide.md for comprehensive testing patterns
- **Ruby UI Components**: See @.claude/guides/ruby-ui-components-guide.md for component usage
- **Deployment**: See @.claude/guides/deployment-guide.md for production deployment

## Architecture & Guides

**For comprehensive architecture details, see @.claude/guides/architecture-guide.md**

### Key Architectural Patterns
- **Phlex Views**: Type-safe, component-based view layer
- **Service Objects**: Business logic in dedicated service classes
- **Authentication Concerns**: `AuthProvider` and `Secured` for auth management
- **Component Composition**: Ruby UI + custom components

### Critical Requirements

#### Internationalization (i18n) 🌍
**CRITICAL**: All view strings MUST use `t()` helper for internationalization.

```ruby
# ❌ NEVER do this
h1 { "Welcome to our application" }

# ✅ ALWAYS do this
h1 { t("views.welcome.title") }
```

**Complete i18n guide: @.claude/guides/i18n-guide.md**

#### Authentication 🔐
**Complete authentication setup: @.claude/guides/authentication-guide.md**

#### Deployment 🚀
**Complete deployment guide: @.claude/guides/deployment-guide.md**

#### Ruby UI Components 🎨
**Complete component reference: @.claude/guides/ruby-ui-components-guide.md**

## Task Management Guidelines

When making task lists, always add to the planning phase:
- Consult context7 MCP for up to date documentation and code snippets

And always append:
- Run Rubocop after making changes, and correct issues if required
- Verify test suite passes

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Quick Reference Links
- Architecture: @.claude/guides/architecture-guide.md
- Authentication: @.claude/guides/authentication-guide.md
- Deployment: @.claude/guides/deployment-guide.md
- I18n: @.claude/guides/i18n-guide.md
- Ruby UI: @.claude/guides/ruby-ui-components-guide.md
- Testing: @.claude/guides/testing-guide.md
- Phlex Testing: @.claude/guides/phlex-testing-guide.md
