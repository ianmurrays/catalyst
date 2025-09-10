# frozen_string_literal: true

class Views::Auth0::Login < Views::Base
  def page_title
    "Sign in"
  end

  def view_template
    div(class: "min-h-screen flex items-center justify-center px-4") do
      div(class: "max-w-md w-full space-y-6 text-center") do
        h1(class: "text-2xl font-semibold text-foreground") { "Sign in" }
        p(class: "text-muted-foreground") { "Click the button below to continue." }

        form(action: "/auth/auth0", method: "post", "data-turbo": "false") do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

          render RubyUI::Button::Button.new(type: :submit, size: :md) do
            "Sign in"
          end
        end
      end
    end
  end
end
