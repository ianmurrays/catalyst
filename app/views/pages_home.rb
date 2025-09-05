# frozen_string_literal: true

class Views::PagesHome < Views::Base
  include Phlex::Rails::Helpers::Routes

  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :current_auth0_user

  def view_template
    div(class: "min-h-screen") do
      navbar_section
      div(class: "bg-gradient-to-b from-muted/50 to-muted") do
        div(class: "container mx-auto px-4 py-16") do
          header_section
          features_section
          cta_section
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
              span(class: "text-muted-foreground") { "Hello, #{current_auth0_user["name"]}" }
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
      h1(class: "text-5xl font-bold text-foreground mb-4") { "Welcome to Catalyst" }
      p(class: "text-xl text-muted-foreground max-w-2xl mx-auto") do
        "A modern Rails application built with Ruby UI components and Phlex"
      end
      div(class: "mt-8 flex gap-4 justify-center") do
        render RubyUI::Button::Button.new(variant: :default, size: :lg) do
          "Get Started"
        end
        render RubyUI::Button::Button.new(variant: :outline, size: :lg) do
          "Learn More"
        end
      end
    end
  end

  def features_section
    div(class: "grid grid-cols-1 md:grid-cols-3 gap-8 mb-16") do
      feature_card(
        title: "Ruby UI Components",
        description: "Beautiful, accessible components built with Phlex and Tailwind CSS",
        badge: "Components"
      )

      feature_card(
        title: "Rails 8 Ready",
        description: "Built on the latest Rails with all the modern features you need",
        badge: "Rails 8"
      )

      feature_card(
        title: "Developer Friendly",
        description: "Clean code, great DX, and easy to customize for your needs",
        badge: "DX"
      )
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

  def cta_section
    div(class: "bg-card border rounded-xl p-12 text-center") do
      h2(class: "text-3xl font-bold text-card-foreground mb-4") { "Ready to build something amazing?" }
      p(class: "text-muted-foreground mb-8 max-w-2xl mx-auto") do
        "This is your starting point for building modern Ruby on Rails applications with beautiful UI components."
      end
      div(class: "flex gap-4 justify-center") do
        render RubyUI::Button::Button.new(variant: :primary, size: :lg) do
          "View Documentation"
        end
        render RubyUI::Badge::Badge.new(variant: :primary) do
          "v1.0.0"
        end
      end
    end
  end
end
