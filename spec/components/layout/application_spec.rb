# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Components::Layout::Application do
  let(:page_info) do
    Views::Base::PageInfo.new(
      title: "Test Title",
      description: "Test Description"
    )
  end

  let(:component) do
    comp = described_class.new(page_info)
    setup_application_layout_mocks(comp)
    comp
  end

  describe "HTML structure" do
    let(:html) { component.call { "Test Content" } }
    let(:doc) { Nokogiri::HTML5(html) }

    it "renders proper DOCTYPE" do
      expect(html).to start_with("<!doctype html>")
    end

    it "renders html element" do
      expect(doc.css('html')).not_to be_empty
    end

    it "renders head section" do
      expect(doc.css('head')).not_to be_empty
    end

    it "renders body section" do
      expect(doc.css('body')).not_to be_empty
    end

    it "includes page title" do
      expect(doc.css('title').text).to eq("Test Title")
    end

    it "defaults to 'Catalyst' when no title provided" do
      page_info = Views::Base::PageInfo.new(title: nil, description: nil)
      comp = described_class.new(page_info)
      setup_application_layout_mocks(comp)

      html = comp.call { "Test Content" }
      doc = Nokogiri::HTML5(html)

      expect(doc.css('title').text).to eq("Catalyst")
    end

    it "includes viewport meta tag" do
      viewport_meta = doc.css('meta[name="viewport"]').first
      expect(viewport_meta['content']).to eq("width=device-width,initial-scale=1")
    end

    it "includes mobile web app meta tags" do
      expect(doc.css('meta[name="apple-mobile-web-app-capable"]').first['content']).to eq("yes")
      expect(doc.css('meta[name="mobile-web-app-capable"]').first['content']).to eq("yes")
    end

    it "includes CSRF meta tag" do
      expect(doc.css('meta[name="csrf-token"]')).not_to be_empty
    end

    it "includes CSP meta tag" do
      expect(doc.css('meta[http-equiv="Content-Security-Policy"]')).not_to be_empty
    end

    it "includes dark mode prevention script" do
      expect(html).to include("localStorage.theme === 'dark'")
      expect(html).to include("document.documentElement.classList.add('dark')")
    end

    it "includes icon links" do
      expect(doc.css('link[rel="icon"][href="/icon.png"]')).not_to be_empty
      expect(doc.css('link[rel="icon"][href="/icon.svg"]')).not_to be_empty
      expect(doc.css('link[rel="apple-touch-icon"]')).not_to be_empty
    end

    it "includes stylesheet links" do
      expect(doc.css('link[rel="stylesheet"][href*="application.tailwind"]')).not_to be_empty
      expect(doc.css('link[rel="stylesheet"][href*="app"]')).not_to be_empty
    end

    it "includes javascript importmap tags" do
      expect(html).to include("importmap")
    end

    it "renders dark-mode background styling" do
      expect(doc.css('body').first['class']).to include("bg-background")
      expect(doc.css('body').first['class']).to include("text-foreground")
    end

    it "renders content inside main element" do
      expect(doc.css('main').text).to include("Test Content")
    end

    it "includes global navbar component" do
      expect(html).to include("Catalyst") # Brand name from navbar
      expect(html).to include("sticky top-0") # Navbar styling
    end
  end

  describe "with head content block" do
    it "yields head content when provided" do
      html = component.call(head: -> { meta(name: "custom", content: "test") }) { "Body Content" }
      doc = Nokogiri::HTML5(html)

      expect(doc.css('meta[name="custom"]').first['content']).to eq("test")
    end
  end

  describe "background styling consistency" do
    let(:doc) { Nokogiri::HTML5(component.call { "Content" }) }

    it "applies consistent background class like profile views" do
      body_classes = doc.css('body').first['class'].split
      expect(body_classes).to include("bg-background")
    end

    it "applies consistent text color like profile views" do
      body_classes = doc.css('body').first['class'].split
      expect(body_classes).to include("text-foreground")
    end

    it "includes min-height for full page coverage" do
      body_classes = doc.css('body').first['class'].split
      expect(body_classes).to include("min-h-screen")
    end
  end
end
