# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Components::Layout::Navbar do
  let(:component) do
    comp = described_class.new
    # Mock Rails helpers for testing
    allow(comp).to receive(:form_authenticity_token).and_return("test-token")
    comp
  end

  describe "structure" do
    let(:html) { component.call }
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
      brand = doc.css('h1').first
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

      let(:html) { component.call }
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

      before do
        allow_any_instance_of(described_class).to receive(:logged_in?).and_return(true)
        allow_any_instance_of(described_class).to receive(:current_user).and_return(mock_user)
      end

      let(:html) { component.call }
      let(:doc) { Nokogiri::HTML5(html) }

      it "shows user greeting with name" do
        expect(html).to include("Hello, John Doe")
      end

      it "includes profile link" do
        profile_link = doc.css('a[href="/profile"]').first
        expect(profile_link).not_to be_nil
        expect(profile_link.text).to include("Profile")
      end

      it "shows logout button" do
        expect(html).to include("Logout")
      end

      it "includes logout form with proper action" do
        form = doc.css('form[action="/auth/logout"]').first
        expect(form).not_to be_nil
        expect(form['method']).to eq("post")
      end

      it "includes DELETE method for logout" do
        method_input = doc.css('input[name="_method"][value="delete"]').first
        expect(method_input).not_to be_nil
      end

      it "includes CSRF token in logout form" do
        expect(doc.css('input[name="authenticity_token"]')).not_to be_empty
      end

      it "disables turbo on logout form" do
        form = doc.css('form[action="/auth/logout"]').first
        expect(form['data-turbo']).to eq("false")
      end

      it "does not show login button" do
        expect(html).not_to include('action="/auth/auth0"')
      end
    end
  end

  describe "theme toggle" do
    let(:html) { component.call }
    let(:doc) { Nokogiri::HTML5(html) }

    it "includes theme toggle component" do
      # Should render the RubyUI::ThemeToggle component
      expect(html).to include("SetLightMode")
      expect(html).to include("SetDarkMode")
    end

    it "includes light mode button with sun icon" do
      # Look for sun icon SVG path
      expect(html).to include("M12 2.25a.75.75 0")
    end

    it "includes dark mode button with moon icon" do
      # Look for moon icon SVG path  
      expect(html).to include("M9.528 1.718a.75.75 0")
    end

    it "renders theme toggle buttons as ghost variants" do
      expect(html).to include("variant: :ghost")
    end
  end

  describe "button styling" do
    context "when not logged in" do
      before do
        allow_any_instance_of(described_class).to receive(:logged_in?).and_return(false)
      end

      let(:html) { component.call }

      it "uses outline variant for login button" do
        expect(html).to include("variant: :outline")
      end

      it "uses medium size for login button" do
        expect(html).to include("size: :md")
      end
    end

    context "when logged in" do
      let(:mock_user) { double("User", name: "John Doe") }

      before do
        allow_any_instance_of(described_class).to receive(:logged_in?).and_return(true)
        allow_any_instance_of(described_class).to receive(:current_user).and_return(mock_user)
      end

      let(:html) { component.call }

      it "uses ghost variant for profile button" do
        expect(html).to include("variant: :ghost")
      end

      it "uses outline variant for logout button" do
        expect(html).to include("variant: :outline")
      end

      it "uses medium size for both buttons" do
        expect(html).to include("size: :md")
      end
    end
  end

  describe "accessibility" do
    let(:html) { component.call }
    let(:doc) { Nokogiri::HTML5(html) }

    it "has proper semantic markup with header element" do
      expect(doc.css('header')).not_to be_empty
    end

    it "uses proper heading hierarchy for brand" do
      expect(doc.css('h1')).not_to be_empty
    end

    it "includes proper button elements for interactive components" do
      expect(doc.css('button, input[type="submit"]')).not_to be_empty
    end
  end

  describe "responsive behavior" do
    let(:html) { component.call }
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