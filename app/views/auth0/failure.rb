# frozen_string_literal: true

class Views::Auth0::Failure < Views::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(error_msg: nil)
    @error_msg = error_msg
  end

  def page_title
    "Authentication Error"
  end

  def view_template
    div(class: "min-h-screen bg-background flex items-center justify-center px-4") do
      div(class: "max-w-md w-full space-y-8") do
        error_header
        error_content
        action_buttons
      end
    end
  end

  private

  def error_header
    div(class: "text-center") do
      div(class: "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100") do
        svg(
          class: "h-6 w-6 text-red-600",
          fill: "none",
          viewBox: "0 0 24 24",
          stroke: "currentColor",
          stroke_width: "2"
        ) do |s|
          s.path(
            stroke_linecap: "round",
            stroke_linejoin: "round",
            d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.124 16.5c-.77.833.192 2.5 1.732 2.5z"
          )
        end
      end
      h2(class: "mt-6 text-3xl font-extrabold text-foreground") do
        "Authentication Failed"
      end
    end
  end

  def error_content
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardContent.new(class: "pt-6") do
        render RubyUI::Alert::Alert.new(variant: :destructive, class: "mb-4") do
          render RubyUI::Alert::AlertTitle.new { "Error" }
          render RubyUI::Alert::AlertDescription.new do
            error_message
          end
        end

        if email_provider_error?
          provider_configuration_help
        end
      end
    end
  end

  def error_message
    @error_msg.presence || "Authentication failed. Please try again."
  end

  def email_provider_error?
    @error_msg&.include?("Email is required from authentication provider")
  end

  def provider_configuration_help
    div(class: "mt-4 p-4 bg-blue-50 rounded-lg border border-blue-200") do
      h4(class: "text-sm font-semibold text-blue-800 mb-2") do
        "Configuration Issue"
      end
      p(class: "text-sm text-blue-700 mb-3") do
        "Your social login provider is not configured to share email addresses. To fix this:"
      end

      ul(class: "text-sm text-blue-700 space-y-1 list-disc list-inside") do
        li { "For GitHub: Enable the 'user:email' scope in your OAuth app settings" }
        li { "For Google: Enable the 'email' scope in your OAuth configuration" }
        li { "Contact your administrator if you're not sure how to configure this" }
      end
    end
  end

  def action_buttons
    div(class: "flex flex-col gap-3") do
      link_to "/auth/auth0", class: "w-full" do
        render RubyUI::Button::Button.new(class: "w-full") do
          "Try Again"
        end
      end

      link_to "/", class: "w-full" do
        render RubyUI::Button::Button.new(variant: :outline, class: "w-full") do
          "Return Home"
        end
      end
    end
  end
end
