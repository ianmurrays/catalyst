# frozen_string_literal: true

class Components::Layout::Application < Components::Base
  register_output_helper :csrf_meta_tags
  register_output_helper :csp_meta_tag
  register_output_helper :stylesheet_link_tag
  register_output_helper :javascript_importmap_tags

  def initialize(page_info, head: nil)
    @page_info = page_info
    @head_block = head
  end

  def view_template
    doctype

    html do
      render_head
      render_body { yield }
    end
  end

  private

  def render_head
    head do
      title { @page_info.title || "Catalyst" }
      meta(name: "description", content: @page_info.description) if @page_info.description

      meta(name: "viewport", content: "width=device-width,initial-scale=1")
      meta(name: "apple-mobile-web-app-capable", content: "yes")
      meta(name: "mobile-web-app-capable", content: "yes")

      csrf_meta_tags
      csp_meta_tag

      # Dark mode prevention script to avoid FOUC
      script(type: "text/javascript") do
        raw(<<~JAVASCRIPT.html_safe)
          // Set theme before page loads to prevent FOUC
          if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
            document.documentElement.classList.add('dark')
          } else {
            document.documentElement.classList.remove('dark')
          }
        JAVASCRIPT
      end

      # Yield additional head content if provided
      @head_block&.call

      # Icon links
      link(rel: "icon", href: "/icon.png", type: "image/png")
      link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
      link(rel: "apple-touch-icon", href: "/icon.png")

      # Stylesheets
      stylesheet_link_tag("application.tailwind", "data-turbo-track": "reload")
      stylesheet_link_tag(:app, "data-turbo-track": "reload")

      # JavaScript
      javascript_importmap_tags
    end
  end

  def render_body
    body(class: body_classes) do
      render Components::Layout::Navbar.new

      main(role: "main") do
        yield
      end
    end
  end

  def body_classes
    [
      "bg-background",      # Consistent with profile views
      "text-foreground",    # Consistent with profile views
      "min-h-screen"        # Full page coverage like profile views
    ].join(" ")
  end
end
