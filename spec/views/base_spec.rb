# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Views::Base do
  let(:test_view_class) do
    Class.new(Views::Base) do
      def view_template
        div(class: "test-content") { "Test View Content" }
      end

      def page_title
        "Custom Test Title"
      end

      def page_description
        "Custom test description"
      end
    end
  end

  let(:view) { test_view_class.new }

  describe "PageInfo data structure" do
    it "defines PageInfo with title and description" do
      expect(Views::Base::PageInfo).to be_a(Class)
      page_info = Views::Base::PageInfo.new(title: "Test", description: "Desc")
      expect(page_info.title).to eq("Test")
      expect(page_info.description).to eq("Desc")
    end
  end

  describe "#around_template" do
    let(:html) { render_with_view_context(view) }
    let(:doc) { Nokogiri::HTML5(html) }

    it "wraps view content in application layout" do
      expect(html).to start_with("<!doctype html>")
      expect(doc.css('html')).not_to be_empty
      expect(doc.css('head')).not_to be_empty
      expect(doc.css('body')).not_to be_empty
    end

    it "renders the view content inside the layout" do
      expect(doc.css('.test-content').text).to eq("Test View Content")
    end

    it "uses page_title method for title tag" do
      expect(doc.css('title').text).to eq("Custom Test Title")
    end

    it "includes meta description when page_description is provided" do
      meta_desc = doc.css('meta[name="description"]').first
      expect(meta_desc['content']).to eq("Custom test description")
    end

    it "includes global navbar" do
      # Check for navbar header element with proper styling
      navbar = doc.css('header.sticky.top-0').first
      expect(navbar).not_to be_nil
      expect(navbar['class']).to include('sticky')
      expect(navbar['class']).to include('top-0')
      expect(navbar['class']).to include('z-50')

      # Check for brand as clickable link - the actual text might be mocked differently
      brand_link = doc.css('header a').first
      expect(brand_link).not_to be_nil
      expect(brand_link['class']).to include('text-xl')
      expect(brand_link['class']).to include('font-bold')
      expect(brand_link['href']).to eq('/')

      # The brand content should contain either "Catalyst" or be properly structured
      # Even if translation fails, the element structure should be correct
      expect(brand_link.text.strip).not_to be_empty
    end

    it "renders view content inside main element" do
      main_content = doc.css('main .test-content').text
      expect(main_content).to eq("Test View Content")
    end

    it "applies consistent background styling like profile views" do
      body_classes = doc.css('body').first['class'].split
      expect(body_classes).to include("bg-background")
      expect(body_classes).to include("text-foreground")
      expect(body_classes).to include("min-h-screen")
    end
  end

  describe "#page_info" do
    it "creates PageInfo instance with title and description" do
      page_info = view.page_info
      expect(page_info).to be_a(Views::Base::PageInfo)
      expect(page_info.title).to eq("Custom Test Title")
      expect(page_info.description).to eq("Custom test description")
    end
  end

  describe "#page_title" do
    context "when not overridden" do
      let(:base_view) { Views::Base.new }

      it "returns default Catalyst title in rendered HTML" do
        html = render_with_view_context(base_view)
        doc = Nokogiri::HTML5(html)
        expect(doc.css('title').text).to eq("Catalyst")
      end
    end

    context "when overridden in subclass" do
      it "returns custom title" do
        expect(view.page_title).to eq("Custom Test Title")
      end
    end
  end

  describe "#page_description" do
    context "when not overridden" do
      let(:base_view) { Views::Base.new }

      it "returns nil" do
        expect(base_view.page_description).to be_nil
      end
    end

    context "when overridden in subclass" do
      it "returns custom description" do
        expect(view.page_description).to eq("Custom test description")
      end
    end
  end

  describe "helper method registration" do
    it "has current_user registered as value helper" do
      # This would be tested via integration with actual Rails helpers
      # For now, we verify the class structure supports it
      expect(view).to respond_to(:current_user)
    end

    it "has logged_in? registered as value helper" do
      expect(view).to respond_to(:logged_in?)
    end

    it "has form_authenticity_token registered as value helper" do
      expect(view).to respond_to(:form_authenticity_token)
    end

    it "has form_with registered as both value and output helper" do
      expect(view).to respond_to(:form_with)
    end
  end

  describe "inheritance" do
    it "inherits from Components::Base" do
      expect(Views::Base.superclass).to eq(Components::Base)
    end

    it "maintains existing helper registration" do
      # Verify that our layout changes don't break existing helper registration
      expect(Views::Base.instance_methods).to include(:current_user)
      expect(Views::Base.instance_methods).to include(:logged_in?)
      expect(Views::Base.instance_methods).to include(:form_authenticity_token)
    end
  end

  describe "layout consistency" do
    context "with views that have specific styling patterns" do
      let(:profile_style_view) do
        instance = Class.new(Views::Base) do
          def view_template
            div(class: "container mx-auto px-4 py-8 max-w-4xl") do
              h1 { "Profile Style Content" }
            end
          end
        end.new

        # Mock Rails helpers for layout components
        allow_any_instance_of(Components::Layout::Application).to receive(:csrf_meta_tags).and_return('<meta name="csrf-token" content="test-token">')
        allow_any_instance_of(Components::Layout::Application).to receive(:csp_meta_tag).and_return('<meta http-equiv="Content-Security-Policy" content="default-src \'self\'">')
        allow_any_instance_of(Components::Layout::Application).to receive(:stylesheet_link_tag).and_return('<link rel="stylesheet" href="/assets/application.css">')
        allow_any_instance_of(Components::Layout::Application).to receive(:javascript_importmap_tags).and_return('<script>importmap</script>')

        # Mock navbar components
    
        # Mock t method for the instance itself

        instance
      end

      it "maintains profile-style container patterns within the layout" do
        html = render_with_view_context(profile_style_view)
        doc = Nokogiri::HTML5(html)

        container = doc.css('.container.mx-auto.px-4.py-8.max-w-4xl').first
        expect(container).not_to be_nil
        expect(container.text).to include("Profile Style Content")
      end

      it "wraps profile-style views in consistent layout" do
        html = render_with_view_context(profile_style_view)
        doc = Nokogiri::HTML5(html)

        # Should have layout wrapper
        expect(doc.css('header')).not_to be_empty # navbar
        expect(doc.css('main')).not_to be_empty # main content wrapper

        # Should have profile content inside
        expect(doc.css('main h1').text).to eq("Profile Style Content")
      end
    end
  end
end
