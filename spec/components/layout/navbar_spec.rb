# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Components::Layout::Navbar do
  let(:component) { described_class.new }

  describe "structure" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "renders header element with sticky positioning" do
      header = doc.css('header').first
      expect(header).not_to be_nil
      expect(header['class']).to include("sticky")
      expect(header['class']).to include("top-0")
      expect(header['class']).to include("z-50")
    end

    it "includes backdrop blur styling" do
      header = doc.css('header').first
      expect(header['class']).to include("backdrop-blur-2xl")
      expect(header['class']).to include("backdrop-saturate-200")
    end

    it "has proper background and border styling" do
      header = doc.css('header').first
      expect(header['class']).to include("bg-background/80")
      expect(header['class']).to include("border-b")
    end

    it "renders brand section" do
      expect(html).to include("Catalyst")
      brand = doc.css('a').first
      expect(brand).not_to be_nil
      expect(brand['class']).to include("text-xl")
      expect(brand['class']).to include("font-bold")
    end

    it "includes responsive container" do
      container = doc.css('div').first
      expect(container['class']).to include("flex")
      expect(container['class']).to include("items-center")
      expect(container['class']).to include("justify-between")
    end
  end

  describe "authentication states" do
    context "when user is not logged in" do
      before do
        allow_any_instance_of(described_class).to receive(:logged_in?).and_return(false)
      end

      let(:html) { render_with_view_context(component) }
      let(:doc) { Nokogiri::HTML5(html) }

      it "shows login button" do
        expect(html).to include("Login")
      end

      it "includes login form with proper action" do
        form = doc.css('form[action="/auth/auth0"]').first
        expect(form).not_to be_nil
        expect(form['method']).to eq("post")
      end

      it "includes CSRF token in login form" do
        expect(doc.css('input[name="authenticity_token"]')).not_to be_empty
      end

      it "disables turbo on login form" do
        form = doc.css('form[action="/auth/auth0"]').first
        expect(form['data-turbo']).to eq("false")
      end

      it "does not show user greeting or profile link" do
        expect(html).not_to include("Hello,")
        expect(html).not_to include("Profile")
      end
    end

    context "when user is logged in" do
      let(:mock_user) { double("User", name: "John Doe", email: "john@example.com") }
      let(:html) { render_with_view_context(described_class.new, user: mock_user) }
      let(:doc) { Nokogiri::HTML5(html) }

      it "shows user greeting with name" do
        expect(html).to include("Hello, John Doe")
      end

      it "includes profile link" do
        profile_link = doc.css('a[href="/profile"]').first
        expect(profile_link).not_to be_nil
        # Profile button should be inside the link
        button = profile_link.css('button').first
        expect(button).not_to be_nil
        expect(profile_link.text.strip).to include("Profile")
      end

      it "shows logout button" do
        logout_button = doc.css('form[action="/auth/logout"] button[type="submit"]').first
        expect(logout_button).not_to be_nil
        expect(logout_button.text.strip).to eq("Logout")
      end

      it "includes logout form with proper action" do
        form = doc.css('form[action="/auth/logout"]').first
        expect(form).not_to be_nil
        expect(form['method']).to eq("post")
      end

      it "includes DELETE method for logout" do
        method_input = doc.css('form[action="/auth/logout"] input[name="_method"][value="delete"]').first
        expect(method_input).not_to be_nil
      end

      it "includes CSRF token in logout form" do
        csrf_input = doc.css('form[action="/auth/logout"] input[name="authenticity_token"]').first
        expect(csrf_input).not_to be_nil
        expect(csrf_input['value']).to eq("test-token")
      end

      it "disables turbo on logout form" do
        form = doc.css('form[action="/auth/logout"]').first
        expect(form['data-turbo']).to eq("false")
      end

      it "does not show login button" do
        login_form = doc.css('form[action="/auth/auth0"]')
        expect(login_form).to be_empty
      end
    end
  end

  describe "theme toggle" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "includes theme toggle component" do
      # Check for light mode toggle div
      light_mode_div = doc.css('div[data-controller="ruby-ui--theme-toggle"]').first
      expect(light_mode_div).not_to be_nil
      expect(light_mode_div['class']).to include('dark:hidden')

      # Check for dark mode toggle div
      dark_mode_div = doc.css('div[data-action*="setLightTheme"]').first
      expect(dark_mode_div).not_to be_nil
      expect(dark_mode_div['class']).to include('hidden')
      expect(dark_mode_div['class']).to include('dark:inline-block')
    end

    it "includes light mode button with sun icon" do
      # Look for sun icon SVG path in the light mode button
      sun_path = doc.css('div.dark\:hidden svg path[d*="M12 2.25a.75.75"]').first
      expect(sun_path).not_to be_nil
    end

    it "includes dark mode button with moon icon" do
      # Look for moon icon SVG path in the dark mode button
      moon_path = doc.css('div.hidden.dark\:inline-block svg path[d*="M9.528 1.718a.75.75"]').first
      expect(moon_path).not_to be_nil
    end

    it "renders theme toggle buttons as ghost variants" do
      # Check specifically for theme toggle buttons (they have the icon styling)
      theme_buttons = doc.css('div[data-controller*="theme-toggle"] button')
      expect(theme_buttons.length).to eq(2) # Light and dark mode buttons

      # Check that both theme buttons have ghost styling
      theme_buttons.each do |button|
        expect(button['class']).to include('hover:bg-accent')
        expect(button['class']).to include('hover:text-accent-foreground')
        # Theme toggle buttons are icon buttons so they should have specific sizing
        expect(button['class']).to include('h-9')
        expect(button['class']).to include('w-9')
      end
    end
  end

  describe "button styling" do
    context "when not logged in" do
      let(:html) { render_with_view_context(component) }
      let(:doc) { Nokogiri::HTML5(html) }

      it "uses outline variant for login button" do
        # Check for outline variant CSS classes on login button
        login_button = doc.css('form[action="/auth/auth0"] button').first
        expect(login_button).not_to be_nil
        expect(login_button['class']).to include('border')
        expect(login_button['class']).to include('border-input')
        expect(login_button['class']).to include('bg-background')
        expect(login_button['class']).to include('shadow-sm')
      end

      it "uses medium size for login button" do
        # Check for medium size CSS classes on login button
        login_button = doc.css('form[action="/auth/auth0"] button').first
        expect(login_button).not_to be_nil
        expect(login_button['class']).to include('px-4')
        expect(login_button['class']).to include('py-2')
        expect(login_button['class']).to include('h-9')
        expect(login_button['class']).to include('text-sm')
      end
    end

    context "when logged in" do
      let(:mock_user) { double("User", name: "John Doe") }
      let(:html) { render_with_view_context(described_class.new, user: mock_user) }
      let(:doc) { Nokogiri::HTML5(html) }

      it "uses ghost variant for profile button" do
        # Check for ghost variant CSS classes on profile button
        profile_button = doc.css('a[href="/profile"] button').first
        expect(profile_button).not_to be_nil
        expect(profile_button['class']).to include('hover:bg-accent')
        expect(profile_button['class']).to include('hover:text-accent-foreground')
        expect(profile_button['class']).not_to include('border') # Ghost doesn't have border
      end

      it "uses outline variant for logout button" do
        # Check for outline variant CSS classes on logout button
        logout_button = doc.css('form[action="/auth/logout"] button').first
        expect(logout_button).not_to be_nil
        expect(logout_button['class']).to include('border')
        expect(logout_button['class']).to include('border-input')
        expect(logout_button['class']).to include('bg-background')
        expect(logout_button['class']).to include('shadow-sm')
      end

      it "uses medium size for both buttons" do
        # Check profile button size
        profile_button = doc.css('a[href="/profile"] button').first
        expect(profile_button).not_to be_nil
        expect(profile_button['class']).to include('px-4')
        expect(profile_button['class']).to include('py-2')
        expect(profile_button['class']).to include('h-9')
        expect(profile_button['class']).to include('text-sm')

        # Check logout button size
        logout_button = doc.css('form[action="/auth/logout"] button').first
        expect(logout_button).not_to be_nil
        expect(logout_button['class']).to include('px-4')
        expect(logout_button['class']).to include('py-2')
        expect(logout_button['class']).to include('h-9')
        expect(logout_button['class']).to include('text-sm')
      end
    end
  end

  describe "accessibility" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "has proper semantic markup with header element" do
      expect(doc.css('header')).not_to be_empty
    end

    it "includes brand as clickable link" do
      brand_link = doc.css('a').first
      expect(brand_link).not_to be_nil
      expect(brand_link.text.strip).to eq("Catalyst")
      expect(brand_link['href']).to eq("/")
    end

    it "includes proper button elements for interactive components" do
      expect(doc.css('button, input[type="submit"]')).not_to be_empty
    end
  end

  describe "responsive behavior" do
    let(:html) { render_with_view_context(component) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "includes responsive flex layout" do
      container = doc.css('div.flex.items-center.justify-between').first
      expect(container).not_to be_nil
    end

    it "includes gap spacing for button groups" do
      nav_section = doc.css('div.flex.items-center.gap-4').first
      expect(nav_section).not_to be_nil
    end
  end
end
