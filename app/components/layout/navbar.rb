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
      h1(class: "text-xl font-bold text-foreground") { t("application.name") }
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
