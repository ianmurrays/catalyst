# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Catalyst" - a Rails 8 application template built with modern tooling and Ruby UI components. It serves as a foundation for Rails applications with pre-configured authentication (Auth0), UI components (Ruby UI with Phlex), and modern CSS (Tailwind 4).

### Key Technologies

- **Rails 8** with modern asset pipeline (Propshaft)
- **Ruby UI** components built with Phlex for view layer abstraction
- **Tailwind CSS 4** for styling with `tailwind_merge` for class composition
- **Auth0** for authentication with CSRF protection
- **RSpec** for testing
- **Solid Cache/Queue/Cable** for Rails background jobs and caching

## Development Commands

### Rails Operations
```bash
bin/rails server                    # Start development server
bin/dev                            # Start development with asset watching
bin/rails console                  # Rails console
bin/rails db:create db:migrate     # Database setup
bin/rails db:seed                  # Seed database
bin/setup                          # Initial project setup
```

### Testing
```bash
bundle exec rspec                  # Run all tests
bundle exec rspec spec/path/to/file_spec.rb  # Run specific test
```

### Code Quality
```bash
bin/rubocop                        # Run linter (omakase style)
bin/rubocop -a                     # Auto-fix issues
bin/brakeman                       # Security analysis
```

### Ruby UI Components
```bash
bin/rails g ruby_ui:install        # Install Ruby UI system
bin/rails g ruby_ui:component ComponentName  # Generate specific component
bin/rails g ruby_ui:component:all  # Generate all available components
```

### Application Renaming
```bash
bin/rename MyNewApp                # Rename application
bin/rename MyNewApp --dry-run      # Preview rename changes
```

## Architecture

### View Layer Architecture
The application uses **Phlex** as the view layer with two main namespaces:
- `Views::` - Application-specific views in `app/views/` 
- `Components::` - Reusable components in `app/components/`

Base classes:
- `Views::Base` - Base class for application views
- `Components::Base` - Base class for components
- `Components::RubyUI::Base` - Base class for Ruby UI components

### Ruby UI Integration
Ruby UI components are generated into `app/components/ruby_ui/` and include:
- Card components (card, card_content, card_description, etc.)
- Button component
- Badge component  
- Link component

Components can be generated individually or all at once using the generators.

### Authentication
Auth0 integration with:
- `Auth0Controller` for handling authentication flow
- `Secured` concern for protecting controllers
- CSRF protection via `omniauth-rails_csrf_protection`

## Task Management Guidelines

When making task lists, always prepend:
- Consult context7 MCP for up to date documentation and code snippets

And always append:
- Run Rubocop after making changes, and correct issues if required

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.