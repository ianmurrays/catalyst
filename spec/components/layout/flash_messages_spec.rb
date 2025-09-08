# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Components::Layout::FlashMessages, type: :component do
  include ComponentHelpers

  let(:component) { described_class.new }

  describe "when no flash messages are present" do
    it "renders nothing" do
      flash_hash = ActionDispatch::Flash::FlashHash.new
      html = render_with_view_context(component, flash: flash_hash)
      expect(html).to be_empty
    end
  end

  describe "when flash messages are present" do
    context "with a single notice message" do
      it "renders a success variant alert" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated successfully"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have success variant classes
        alert = doc.css('[class*="ring-success"]').first
        expect(alert).not_to be_nil
      end

      it "renders the message in an AlertDescription" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated successfully"
        html = render_with_view_context(component, flash: flash_hash)
        expect(html).to include("Profile updated successfully")
      end

      it "includes a check icon" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated successfully"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have an SVG icon (check icon)
        icon = doc.css('svg').first
        expect(icon).not_to be_nil
      end

      it "includes a dismiss button" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated successfully"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        button = doc.css('button[data-action*="flash-message#dismiss"]').first
        expect(button).not_to be_nil
      end
    end

    context "with a warning/alert message" do
      it "renders a warning variant alert" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:alert] = "Please verify your email"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have warning variant classes
        alert = doc.css('[class*="ring-warning"]').first
        expect(alert).not_to be_nil
      end

      it "includes a warning icon" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:alert] = "Please verify your email"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have an SVG icon (warning icon)
        icon = doc.css('svg').first
        expect(icon).not_to be_nil
      end
    end

    context "with an error message" do
      it "renders a destructive variant alert" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:error] = "Something went wrong"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have destructive variant classes
        alert = doc.css('[class*="ring-destructive"]').first
        expect(alert).not_to be_nil
      end

      it "includes a close/X icon for destructive messages" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:error] = "Something went wrong"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have an SVG icon (close/X icon)
        icon = doc.css('svg').first
        expect(icon).not_to be_nil
      end
    end

    context "with multiple flash messages" do
      it "renders all messages in a stacked container" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated"
        flash_hash[:error] = "Email is invalid"
        flash_hash[:alert] = "Please check your settings"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have a container with space-y classes for stacking
        container = doc.css('.space-y-2').first
        expect(container).not_to be_nil

        # Should have multiple alert components
        alerts = doc.css('[class*="ring-"]')
        expect(alerts.size).to eq(3)
      end

      it "renders each message with appropriate variant" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated"
        flash_hash[:error] = "Email is invalid"
        flash_hash[:alert] = "Please check your settings"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        expect(doc.css('[class*="ring-success"]').size).to eq(1)  # notice
        expect(doc.css('[class*="ring-destructive"]').size).to eq(1)  # error
        expect(doc.css('[class*="ring-warning"]').size).to eq(1)  # alert
      end

      it "includes dismiss buttons for each message" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:notice] = "Profile updated"
        flash_hash[:error] = "Email is invalid"
        flash_hash[:alert] = "Please check your settings"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        buttons = doc.css('button[data-action*="flash-message#dismiss"]')
        expect(buttons.size).to eq(3)
      end
    end

    context "with custom flash types" do
      it "maps success type to success variant" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:success] = "Operation completed"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        alert = doc.css('[class*="ring-success"]').first
        expect(alert).not_to be_nil
      end
    end

    context "with unknown flash type" do
      it "uses default variant for unknown types" do
        flash_hash = ActionDispatch::Flash::FlashHash.new
        flash_hash[:custom] = "Custom message"
        html = render_with_view_context(component, flash: flash_hash)
        doc = Nokogiri::HTML5(html)

        # Should have default variant (no specific color ring class)
        alert = doc.css('[class*="ring-border"]').first
        expect(alert).not_to be_nil
      end
    end
  end

  describe "HTML structure" do
    it "has proper container classes for styling" do
      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[:notice] = "Test message"
      html = render_with_view_context(component, flash: flash_hash)
      doc = Nokogiri::HTML5(html)

      container = doc.css('.container.mx-auto.px-4.py-2').first
      expect(container).not_to be_nil
    end

    it "has relative positioning for dismiss button placement" do
      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[:notice] = "Test message"
      html = render_with_view_context(component, flash: flash_hash)
      doc = Nokogiri::HTML5(html)

      alert = doc.css('.relative').first
      expect(alert).not_to be_nil
    end

    it "positions dismiss button absolutely in top right" do
      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[:notice] = "Test message"
      html = render_with_view_context(component, flash: flash_hash)
      doc = Nokogiri::HTML5(html)

      button = doc.css('button.absolute.top-3.right-3').first
      expect(button).not_to be_nil
    end
  end
end
