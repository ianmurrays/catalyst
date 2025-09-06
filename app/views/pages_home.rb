# frozen_string_literal: true

class Views::PagesHome < Views::Base
  include Phlex::Rails::Helpers::Routes

  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :current_user

  def view_template
    div(class: "min-h-screen") do
      navbar_section
      div(class: "bg-gradient-to-b from-muted/50 to-muted") do
        div(class: "container mx-auto px-4 py-16") do
          header_section
          getting_started_section
          features_section
          development_workflow_section
          next_steps_section
        end
      end
    end
  end

  private

  def navbar_section
    header(class: "sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-2xl backdrop-saturate-200 block") do
      div(class: "w-full max-w-none px-4 flex h-14 items-center justify-between") do
        div(class: "flex items-center") do
          h1(class: "text-xl font-bold text-foreground") { "Catalyst" }
        end
        div(class: "flex items-center gap-4") do
          if logged_in?
            div(class: "flex items-center gap-4") do
              span(class: "text-muted-foreground") { "Hello, #{current_user.name}" }

              a(href: "/profile", class: "inline-flex") do
                render RubyUI::Button::Button.new(variant: :ghost, size: :md) do
                  "Profile"
                end
              end

              form(action: "/auth/logout", method: "post", "data-turbo": "false") do
                input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
                input(type: "hidden", name: "_method", value: "delete")

                render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md) do
                  "Logout"
                end
              end
            end
          else
            form(action: "/auth/auth0", method: "post", "data-turbo": "false") do
              input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

              render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md) do
                "Login"
              end
            end
          end

          render RubyUI::ThemeToggle::ThemeToggle.new do
            render RubyUI::ThemeToggle::SetLightMode.new do
              render RubyUI::Button::Button.new(variant: :ghost, icon: true) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  viewbox: "0 0 24 24",
                  fill: "currentColor",
                  class: "w-4 h-4"
                ) do |s|
                  s.path(
                    d: "M12 2.25a.75.75 0 01.75.75v2.25a.75.75 0 01-1.5 0V3a.75.75 0 01.75-.75zM7.5 12a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM18.894 6.166a.75.75 0 00-1.06-1.06l-1.591 1.59a.75.75 0 101.06 1.061l1.591-1.59zM21.75 12a.75.75 0 01-.75.75h-2.25a.75.75 0 010-1.5H21a.75.75 0 01.75.75zM17.834 18.894a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 10-1.061 1.06l1.59 1.591zM12 18a.75.75 0 01.75.75V21a.75.75 0 01-1.5 0v-2.25A.75.75 0 0112 18zM7.758 17.303a.75.75 0 00-1.061-1.06l-1.591 1.59a.75.75 0 001.06 1.061l1.591-1.59zM6 12a.75.75 0 01-.75.75H3a.75.75 0 010-1.5h2.25A.75.75 0 016 12zM6.697 7.757a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 00-1.061 1.06l1.59 1.591z"
                  )
                end
              end
            end
            render RubyUI::ThemeToggle::SetDarkMode.new do
              render RubyUI::Button::Button.new(variant: :ghost, icon: true) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  viewbox: "0 0 24 24",
                  fill: "currentColor",
                  class: "w-4 h-4"
                ) do |s|
                  s.path(
                    fill_rule: "evenodd",
                    d: "M9.528 1.718a.75.75 0 01.162.819A8.97 8.97 0 009 6a9 9 0 009 9 8.97 8.97 0 003.463-.69.75.75 0 01.981.98 10.503 10.503 0 01-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 01.818.162z",
                    clip_rule: "evenodd"
                  )
                end
              end
            end
          end
        end
      end
    end
  end

  def header_section
    div(class: "text-center mb-16") do
      div(class: "mb-6") do
        render RubyUI::Badge::Badge.new(variant: :primary, class: "mb-4") do
          "Rails 8 Template"
        end
      end
      h1(class: "text-5xl font-bold text-foreground mb-4") { "Catalyst Rails Template" }
      p(class: "text-xl text-muted-foreground max-w-3xl mx-auto mb-8") do
        "A modern Rails 8 application template with Ruby UI components, Auth0 authentication, and Tailwind CSS. Get started building your next application in minutes, not hours."
      end

      div(class: "bg-muted/30 rounded-lg p-6 max-w-2xl mx-auto mb-8") do
        div(class: "text-sm text-muted-foreground mb-2") { "Quick Start" }
        div(class: "font-mono text-sm bg-card border rounded p-3") do
          "bin/rename YourAppName && bin/setup"
        end
      end

      div(class: "flex gap-4 justify-center") do
        render RubyUI::Button::Button.new(variant: :default, size: :lg) do
          "Documentation"
        end
        render RubyUI::Button::Button.new(variant: :outline, size: :lg) do
          "View on GitHub"
        end
      end
    end
  end

  def getting_started_section
    div(class: "mb-16") do
      h2(class: "text-3xl font-bold text-center text-foreground mb-12") { "Getting Started" }

      div(class: "max-w-4xl mx-auto space-y-8") do
        step_card(
          number: "1",
          title: "Clone and Rename",
          description: "Clone this template and rename it to your project name",
          code: "git clone https://github.com/your-org/catalyst.git my-app\ncd my-app\nbin/rename MyApp"
        )

        step_card(
          number: "2",
          title: "Setup Dependencies",
          description: "Install Ruby gems and run the setup script",
          code: "bin/setup"
        )

        step_card(
          number: "3",
          title: "Configure Auth0",
          description: "Set up your Auth0 credentials in your environment",
          code: "# Add to .env or environment variables:\nAUTH0_DOMAIN=your-domain.auth0.com\nAUTH0_CLIENT_ID=your-client-id\nAUTH0_CLIENT_SECRET=your-client-secret"
        )

        step_card(
          number: "4",
          title: "Start Development",
          description: "Launch the development server and start building",
          code: "bin/dev"
        )
      end
    end
  end

  def step_card(number:, title:, description:, code:)
    div(class: "flex gap-6 p-6 bg-card border rounded-xl") do
      div(class: "flex-shrink-0") do
        div(class: "w-10 h-10 bg-primary text-primary-foreground rounded-full flex items-center justify-center font-bold text-lg") do
          number
        end
      end

      div(class: "flex-1") do
        h3(class: "text-xl font-semibold text-card-foreground mb-2") { title }
        p(class: "text-muted-foreground mb-4") { description }
        div(class: "bg-muted rounded-lg p-4") do
          pre(class: "font-mono text-sm text-foreground whitespace-pre-wrap") { code }
        end
      end
    end
  end

  def features_section
    div(class: "mb-16") do
      h2(class: "text-3xl font-bold text-center text-foreground mb-12") { "Features & Stack" }

      div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6") do
        tech_stack_card(
          title: "Rails 8",
          description: "Latest Rails with Propshaft asset pipeline, Solid Cache/Queue/Cable",
          badge: "Backend",
          icon: "🚀",
          details: [ "Modern asset pipeline", "Background jobs", "WebSocket support", "Caching layer" ]
        )

        tech_stack_card(
          title: "Ruby UI Components",
          description: "40+ accessible components built with Phlex and Tailwind CSS",
          badge: "UI",
          icon: "🎨",
          details: [ "Accordion, Alert, Avatar", "Button, Card, Dialog", "Form, Input, Table", "Theme Toggle & more" ]
        )

        tech_stack_card(
          title: "Auth0 Integration",
          description: "Production-ready authentication with CSRF protection",
          badge: "Auth",
          icon: "🔐",
          details: [ "Social login", "User management", "Session handling", "Security features" ]
        )

        tech_stack_card(
          title: "Tailwind CSS 4",
          description: "Modern CSS framework with design tokens and utilities",
          badge: "Styling",
          icon: "💅",
          details: [ "Dark mode support", "Responsive design", "Custom components", "Design system" ]
        )

        tech_stack_card(
          title: "Testing & Quality",
          description: "RSpec, Brakeman, and Rubocop for code quality",
          badge: "Testing",
          icon: "✅",
          details: [ "RSpec test suite", "Security analysis", "Code linting", "Best practices" ]
        )

        tech_stack_card(
          title: "Developer Experience",
          description: "Hot reloading, generators, and modern tooling",
          badge: "DX",
          icon: "⚡",
          details: [ "bin/dev server", "Component generators", "App renaming", "Documentation" ]
        )
      end
    end
  end

  def tech_stack_card(title:, description:, badge:, icon:, details:)
    render RubyUI::Card::Card.new(class: "hover:shadow-lg transition-all duration-200 hover:-translate-y-1") do
      render RubyUI::Card::CardHeader.new do
        div(class: "flex justify-between items-start mb-2") do
          div(class: "flex items-center gap-3") do
            span(class: "text-2xl") { icon }
            render RubyUI::Card::CardTitle.new(class: "text-lg") { title }
          end
          render RubyUI::Badge::Badge.new(variant: :secondary, class: "text-xs") { badge }
        end
        render RubyUI::Card::CardDescription.new { description }
      end
      render RubyUI::Card::CardContent.new do
        ul(class: "text-sm text-muted-foreground space-y-1") do
          details.each do |detail|
            li(class: "flex items-center gap-2") do
              span(class: "w-1 h-1 bg-primary rounded-full flex-shrink-0") { "" }
              span { detail }
            end
          end
        end
      end
    end
  end

  def development_workflow_section
    div(class: "mb-16") do
      h2(class: "text-3xl font-bold text-center text-foreground mb-12") { "Development Workflow" }

      div(class: "grid grid-cols-1 lg:grid-cols-2 gap-8 max-w-6xl mx-auto") do
        workflow_card(
          title: "Common Commands",
          icon: "⚡",
          commands: [
            { cmd: "bin/dev", desc: "Start development server with asset watching" },
            { cmd: "bin/rails console", desc: "Open Rails console" },
            { cmd: "bin/rails db:migrate", desc: "Run database migrations" },
            { cmd: "bundle exec rspec", desc: "Run test suite" }
          ]
        )

        workflow_card(
          title: "Code Quality",
          icon: "✨",
          commands: [
            { cmd: "bin/rubocop", desc: "Run code linter" },
            { cmd: "bin/rubocop -a", desc: "Auto-fix linting issues" },
            { cmd: "bin/brakeman", desc: "Security vulnerability scan" },
            { cmd: "bundle exec rspec spec/", desc: "Run specific tests" }
          ]
        )

        workflow_card(
          title: "Ruby UI Components",
          icon: "🎨",
          commands: [
            { cmd: "bin/rails g ruby_ui:install", desc: "Install Ruby UI system" },
            { cmd: "bin/rails g ruby_ui:component Button", desc: "Generate specific component" },
            { cmd: "bin/rails g ruby_ui:component:all", desc: "Generate all components" },
            { cmd: "bin/rails g ruby_ui:theme", desc: "Customize theme colors" }
          ]
        )

        workflow_card(
          title: "Application Management",
          icon: "🔧",
          commands: [
            { cmd: "bin/rename MyApp", desc: "Rename application" },
            { cmd: "bin/rename MyApp --dry-run", desc: "Preview rename changes" },
            { cmd: "bin/setup", desc: "Initial project setup" },
            { cmd: "rails tmp:clear", desc: "Clear Rails cache" }
          ]
        )
      end
    end
  end

  def workflow_card(title:, icon:, commands:)
    render RubyUI::Card::Card.new(class: "h-full") do
      render RubyUI::Card::CardHeader.new do
        div(class: "flex items-center gap-3") do
          span(class: "text-2xl") { icon }
          render RubyUI::Card::CardTitle.new { title }
        end
      end
      render RubyUI::Card::CardContent.new do
        div(class: "space-y-3") do
          commands.each do |command|
            div(class: "border-l-2 border-primary/20 pl-4 py-2") do
              div(class: "font-mono text-sm text-primary font-medium mb-1") { command[:cmd] }
              div(class: "text-xs text-muted-foreground") { command[:desc] }
            end
          end
        end
      end
    end
  end

  def feature_card(title:, description:, badge:)
    render RubyUI::Card::Card.new(class: "hover:shadow-lg transition-shadow") do
      render RubyUI::Card::CardHeader.new do
        div(class: "flex justify-between items-start") do
          render RubyUI::Card::CardTitle.new { title }
          render RubyUI::Badge::Badge.new(variant: :primary) { badge }
        end
      end
      render RubyUI::Card::CardContent.new do
        render RubyUI::Card::CardDescription.new { description }
      end
      render RubyUI::Card::CardFooter.new do
        render RubyUI::Button::Button.new(variant: :ghost, size: :sm) do
          "Explore →"
        end
      end
    end
  end

  def next_steps_section
    div(class: "bg-card border rounded-xl p-12") do
      h2(class: "text-3xl font-bold text-center text-card-foreground mb-8") { "Next Steps" }
      div(class: "grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8") do
        div do
          h3(class: "text-xl font-semibold text-card-foreground mb-4") { "📚 Documentation & Resources" }
          div(class: "space-y-3") do
            resource_link("📋 CLAUDE.md", "Project-specific development guide")
            resource_link("🔄 docs/RENAMING.md", "Complete app renaming documentation")
            resource_link("🎨 Ruby UI Docs", "Component library documentation")
            resource_link("🔐 Auth0 Setup", "Authentication configuration guide")
            resource_link("🚀 Rails 8 Guide", "Latest Rails features and best practices")
          end
        end

        div do
          h3(class: "text-xl font-semibold text-card-foreground mb-4") { "⚙️ Customization" }
          div(class: "space-y-3") do
            customization_item("Update branding colors in tailwind.config.js")
            customization_item("Configure Auth0 with your domain settings")
            customization_item("Add your preferred Ruby UI components")
            customization_item("Customize the application layout")
            customization_item("Set up your deployment pipeline")
          end
        end
      end

      div(class: "bg-muted/30 rounded-lg p-6 mb-8") do
        h3(class: "text-lg font-semibold text-card-foreground mb-3") { "🚀 Production Checklist" }
        div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
          checklist_item("Set up production database")
          checklist_item("Configure environment variables")
          checklist_item("Set up SSL certificates")
          checklist_item("Configure background job processing")
          checklist_item("Set up monitoring and logging")
          checklist_item("Run security audit (Brakeman)")
        end
      end

      div(class: "text-center") do
        div(class: "flex flex-wrap gap-4 justify-center mb-6") do
          render RubyUI::Button::Button.new(variant: :primary, size: :lg) do
            "🔗 View Full Documentation"
          end
          render RubyUI::Button::Button.new(variant: :outline, size: :lg) do
            "🐙 GitHub Repository"
          end
        end

        div(class: "flex items-center justify-center gap-4") do
          render RubyUI::Badge::Badge.new(variant: :primary) { "Rails 8" }
          render RubyUI::Badge::Badge.new(variant: :secondary) { "Ruby UI" }
          render RubyUI::Badge::Badge.new(variant: :secondary) { "Tailwind 4" }
          render RubyUI::Badge::Badge.new(variant: :secondary) { "Auth0" }
        end
      end
    end
  end

  private

  def resource_link(title, description)
    div(class: "flex items-start gap-3 p-3 rounded-lg hover:bg-muted/50 transition-colors cursor-pointer") do
      div do
        div(class: "font-medium text-sm text-card-foreground") { title }
        div(class: "text-xs text-muted-foreground") { description }
      end
    end
  end

  def customization_item(text)
    div(class: "flex items-start gap-2 text-sm text-muted-foreground") do
      span(class: "w-1.5 h-1.5 bg-primary rounded-full flex-shrink-0 mt-2") { "" }
      span { text }
    end
  end

  def checklist_item(text)
    div(class: "flex items-center gap-2 text-sm text-muted-foreground") do
      span(class: "w-4 h-4 border border-primary/20 rounded flex-shrink-0") { "" }
      span { text }
    end
  end
end
