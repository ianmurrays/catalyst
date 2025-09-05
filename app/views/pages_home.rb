# frozen_string_literal: true

class Views::PagesHome < Views::Base
  include Phlex::Rails::Helpers::Routes

  def view_template
    div(class: "min-h-screen bg-gradient-to-b from-slate-50 to-slate-100") do
      div(class: "container mx-auto px-4 py-16") do
        header_section
        features_section
        cta_section
      end
    end
  end

  private

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
          render RubyUI::Badge::Badge.new(variant: :secondary) { badge }
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
