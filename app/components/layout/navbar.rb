# frozen_string_literal: true

class Components::Layout::Navbar < Components::Base
  register_value_helper :current_user
  register_value_helper :logged_in?
  register_value_helper :form_authenticity_token

  def view_template
    header(class: "sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-2xl backdrop-saturate-200 block") do
      div(class: "w-full max-w-none px-4 flex h-14 items-center justify-between") do
        brand_section
        navigation_section
      end
    end
  end

  private

  def brand_section
    div(class: "flex items-center") do
      link_to t("application.name"), root_path, class: "text-xl font-bold text-foreground no-underline hover:text-foreground/80 transition-colors"
    end
  end

  def navigation_section
    div(class: "flex items-center gap-4") do
      if logged_in?
        authenticated_user_section
      else
        unauthenticated_user_section
      end

      theme_toggle_section
    end
  end

  def authenticated_user_section
    div(class: "flex items-center gap-4") do
      span(class: "text-muted-foreground") { t("navigation.greeting", name: current_user.name) }

      a(href: "/profile", class: "inline-flex") do
        render RubyUI::Button::Button.new(variant: :ghost, size: :md) do
          t("navigation.profile")
        end
      end

      form(action: "/auth/logout", method: "post", "data-turbo": "false") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "delete")

        render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md) do
          t("navigation.logout")
        end
      end
    end
  end

  def unauthenticated_user_section
    form(action: "/auth/auth0", method: "post", "data-turbo": "false") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md) do
        t("navigation.login")
      end
    end
  end

  def theme_toggle_section
    render RubyUI::ThemeToggle::ThemeToggle.new do
      render RubyUI::ThemeToggle::SetLightMode.new do
        render RubyUI::Button::Button.new(variant: :ghost, icon: true) do
          render Components::Icons::Sun.new(size: :sm)
        end
      end

      render RubyUI::ThemeToggle::SetDarkMode.new do
        render RubyUI::Button::Button.new(variant: :ghost, icon: true) do
          render Components::Icons::Moon.new(size: :sm)
        end
      end
    end
  end
end
