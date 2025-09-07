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
    div(class: "flex items-center gap-4", data: { controller: "mobile-menu" }) do
      mobile_menu_button

      # Desktop navigation (hidden on mobile)
      div(class: "hidden md:flex items-center gap-4") do
        if logged_in?
          authenticated_user_section
        else
          unauthenticated_user_section
        end

        theme_toggle_section
      end

      # Mobile menu drawer
      mobile_menu_drawer
    end
  end

  def authenticated_user_section
    div(class: "flex items-center gap-4") do
      div(class: "flex items-center gap-2") do
        render RubyUI::Avatar::Avatar.new(size: :sm) do
          if current_user.avatar.attached?
            render RubyUI::Avatar::AvatarImage.new(
              src: current_user.avatar_url(:thumb),
              alt: current_user.name
            )
          end
          render RubyUI::Avatar::AvatarFallback.new do
            current_user.display_name&.first&.upcase || current_user.email.first.upcase
          end
        end
        span(class: "text-muted-foreground hidden sm:inline") { t("navigation.greeting", name: current_user.name) }
      end

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

  def mobile_menu_button
    render RubyUI::Button::Button.new(
      variant: :ghost,
      icon: true,
      class: "flex md:hidden",
      data: { action: "click->mobile-menu#open" }
    ) do
      render Components::Icons::Menu.new(size: :sm)
    end
  end

  def mobile_menu_drawer
    render RubyUI::Sheet::Sheet.new do
      render RubyUI::Sheet::SheetTrigger.new(
        class: "hidden",
        data: { mobile_menu_target: "trigger" }
      ) do
        # Hidden trigger - controlled by Stimulus
      end

      render RubyUI::Sheet::SheetContent.new(side: :left, class: "w-80") do
        render RubyUI::Sheet::SheetHeader.new do
          render RubyUI::Sheet::SheetTitle.new do
            t("application.name")
          end
        end

        mobile_navigation_items
      end
    end
  end

  def mobile_navigation_items
    div(class: "flex flex-col space-y-4 mt-6") do
      if logged_in?
        mobile_authenticated_user_section
      else
        mobile_unauthenticated_user_section
      end

      # Theme toggle in mobile menu
      div(class: "pt-4 border-t border-border") do
        theme_toggle_section
      end
    end
  end

  def mobile_authenticated_user_section
    div(class: "flex flex-col space-y-4") do
      span(class: "text-muted-foreground px-4") { t("navigation.greeting", name: current_user.name) }

      a(href: "/profile", class: "inline-flex") do
        render RubyUI::Button::Button.new(variant: :ghost, size: :md, class: "w-full justify-start") do
          t("navigation.profile")
        end
      end

      form(action: "/auth/logout", method: "post", "data-turbo": "false") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "delete")

        render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md, class: "w-full justify-start") do
          t("navigation.logout")
        end
      end
    end
  end

  def mobile_unauthenticated_user_section
    form(action: "/auth/auth0", method: "post", "data-turbo": "false", class: "px-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render RubyUI::Button::Button.new(type: :submit, variant: :outline, size: :md, class: "w-full justify-start") do
        t("navigation.login")
      end
    end
  end
end
