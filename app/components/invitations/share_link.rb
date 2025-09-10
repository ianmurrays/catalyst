# frozen_string_literal: true

class Components::Invitations::ShareLink < Components::Base
  def initialize(url:)
    @url = url
  end

  def view_template
    div(class: "space-y-2") do
      label(class: "block text-sm font-medium text-gray-700") { t("invitations.new.share_link_label", default: "Invitation Link") }

      input(
        type: "text",
        value: @url,
        readonly: true,
        class: "w-full rounded-md border border-gray-300 bg-gray-50 p-2 text-gray-700"
      )

      button(
        type: "button",
        class: "inline-flex items-center rounded-md bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700",
        data: {
          controller: "copy-to-clipboard",
          "copy-to-clipboard-text-value": @url,
          action: "click->copy-to-clipboard#copy"
        }
      ) { t("invitations.new.copy_link_button", default: "Copy link") }
    end
  end
end
