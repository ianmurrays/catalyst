# frozen_string_literal: true

class Components::Layout::FlashMessages < Components::Base
  register_value_helper :flash

  def view_template
    return if flash.empty?

    div(class: "container mx-auto px-4 py-2 space-y-2") do
      flash.each do |type, message|
        render_flash_message(type.to_s, message)
      end
    end
  end

  private

  def render_flash_message(type, message)
    variant = variant_for_type(type)

    render RubyUI::Alert::Alert.new(
      variant: variant,
      class: "relative",
      data: { controller: "flash-message" }
    ) do
      # Icon
      render icon_for_variant(variant)

      # Message
      render RubyUI::Alert::AlertDescription.new do
        plain message
      end

      # Dismiss button
      button(
        type: "button",
        class: "absolute top-3 right-3 opacity-70 hover:opacity-100 transition-opacity",
        data: { action: "click->flash-message#dismiss" },
        "aria-label": t("common.buttons.dismiss")
      ) do
        render Components::Icons::Close.new(size: :sm)
      end
    end
  end

  def variant_for_type(type)
    case type
    when "notice", "success"
      :success
    when "alert", "warning"
      :warning
    when "error", "danger"
      :destructive
    else
      nil # default variant
    end
  end

  def icon_for_variant(variant)
    icon_class = case variant
    when :success
      Components::Icons::Check
    when :warning
      Components::Icons::Warning
    when :destructive
      Components::Icons::Close
    else
      Components::Icons::Info
    end

    icon_class.new(size: :sm)
  end
end
