# frozen_string_literal: true

class Views::PagesHome < Views::Base
  include Phlex::Rails::Helpers::Routes

  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token
  register_value_helper :current_auth0_user

  def view_template
    div(class: "min-h-screen") do
      navbar_section
      div(class: "bg-gradient-to-b from-slate-50 to-slate-100") do
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
    header(class: "sticky top-0 z-50 w-full border-b bg-white/80 backdrop-blur-2xl backdrop-saturate-200 block") do
      div(class: "w-full max-w-none px-4 flex h-14 items-center justify-between") do
        div(class: "flex items-center") do
          h1(class: "text-xl font-bold text-slate-900") { "Catalyst" }
        end
        div(class: "flex items-center") do
          if logged_in?
            div(class: "flex items-center gap-4") do
              span(class: "text-slate-700") { "Hello, #{current_auth0_user["name"]}" }
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
        end
      end
    end
  end

  def header_section
    div(class: "text-center mb-16") do
      h1(class: "text-5xl font-bold text-slate-900 mb-4") { "Welcome to Catalyst" }
      p(class: "text-xl text-slate-600 max-w-2xl mx-auto") do
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
    div(class: "bg-slate-900 rounded-xl p-12 text-center") do
      h2(class: "text-3xl font-bold text-white mb-4") { "Ready to build something amazing?" }
      p(class: "text-slate-300 mb-8 max-w-2xl mx-auto") do
        "This is your starting point for building modern Ruby on Rails applications with beautiful UI components."
      end
      div(class: "flex gap-4 justify-center") do
        render RubyUI::Button::Button.new(variant: :secondary, size: :lg) do
          "View Documentation"
        end
        render RubyUI::Badge::Badge.new(variant: :outline, class: "text-white border-white px-4 py-2") do
          "v1.0.0"
        end
      end
    end
  end
end
