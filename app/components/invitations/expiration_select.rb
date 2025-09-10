# frozen_string_literal: true

class Components::Invitations::ExpirationSelect < Components::Base
  def initialize(name:, id:, selected: nil)
    @name = name
    @id = id
    @selected = selected
  end

  def view_template
    render RubyUI::Select::Select.new do
      render RubyUI::Select::SelectInput.new(
        id: @id,
        name: @name,
        value: @selected
      )

      render RubyUI::Select::SelectTrigger.new(class: "w-full") do
        render RubyUI::Select::SelectValue.new(
          placeholder: t("invitations.new.expiration_placeholder", default: "Select expiration")
        )
      end

      render RubyUI::Select::SelectContent.new do
        options.each do |value, label|
          render RubyUI::Select::SelectItem.new(value: value) do
            label
          end
        end
      end
    end
  end

  private

  # Values must map to InvitationsController#parse_expires_in
  def options
    [
      [ "1h", t("invitations.new.expiration_1h", default: "1 hour") ],
      [ "1d", t("invitations.new.expiration_1d", default: "1 day") ],
      [ "3d", t("invitations.new.expiration_3d", default: "3 days") ],
      [ "1w", t("invitations.new.expiration_1w", default: "1 week") ],
      [ "never", t("invitations.new.expiration_never", default: "Never") ]
    ]
  end
end
