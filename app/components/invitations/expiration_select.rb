# frozen_string_literal: true

class Components::Invitations::ExpirationSelect < Components::Base
  def initialize(name:, id:, selected: nil)
    @name = name
    @id = id
    @selected = selected
  end

  def view_template
    select(
      id: @id,
      name: @name,
      class: "w-full rounded-md border border-gray-300 p-2"
    ) do
      options.each do |value, label|
        option(value: value, selected: value == @selected) { label }
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
