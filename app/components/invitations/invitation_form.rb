# frozen_string_literal: true

class Components::Invitations::InvitationForm < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(team:, invitation:, url:, method:, submit_text:)
    @team = team
    @invitation = invitation
    @url = url
    @method = method
    @submit_text = submit_text
  end

  def view_template
    form_with(
      model: @invitation,
      url: @url,
      method: @method,
      class: "space-y-6"
    ) do |form|
      render_form_fields(form)
      render_form_actions
    end
  end

  private

  def render_form_fields(form)
    div(class: "space-y-4") do
      # Role select
      div do
        label(class: "block text-sm font-medium text-gray-700 mb-1", for: "invitation_role") do
          t("invitations.new.role_label")
        end

        select(
          id: "invitation_role",
          name: "invitation[role]",
          class: "w-full rounded-md border border-gray-300 p-2"
        ) do
          available_roles.each do |value, label|
            option(value: value, selected: @invitation.role.to_s == value) { label }
          end
        end
      end

      # Expiration select
      div do
        label(class: "block text-sm font-medium text-gray-700 mb-1", for: "invitation_expires_in") do
          t("invitations.new.expiration_label", default: "Expiration")
        end

        render Components::Invitations::ExpirationSelect.new(
          name: "invitation[expires_in]",
          id: "invitation_expires_in"
        )
      end
    end
  end

  def render_form_actions
    div(class: "flex items-center justify-end gap-3 pt-2") do
      render RubyUI::Button::Button.new(variant: :primary, type: "submit") do
        @submit_text
      end
    end
  end

  # Determine allowed roles based on current user's role in this team.
  # - Owner can invite any role
  # - Admin can invite admin, member, viewer (not owner)
  # - Member/Viewer cannot invite (controller/policy guard), but keep method safe
  def available_roles
    inviter_role = @team.member_role(current_user).to_s

    labels = {
      "owner" => "Owner",
      "admin" => "Admin",
      "member" => "Member",
      "viewer" => "Viewer"
    }

    case inviter_role
    when "owner"
      %w[owner admin member viewer]
    when "admin"
      %w[admin member viewer]
    else
      %w[member viewer]
    end.map { |r| [ r, labels[r] ] }
  end
end
