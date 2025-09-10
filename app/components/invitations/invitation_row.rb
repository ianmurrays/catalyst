# frozen_string_literal: true

class Components::Invitations::InvitationRow < Components::Base
  def initialize(invitation:, team:)
    @invitation = invitation
    @team = team
  end

  def view_template
    tr(class: "border-b last:border-b-0") do
      td(class: "px-4 py-3 text-sm text-gray-900") { role_badge }
      td(class: "px-4 py-3 text-sm text-gray-700") { @invitation.creator_name || "-" }
      td(class: "px-4 py-3 text-sm text-gray-700") { status_chip }
      td(class: "px-4 py-3 text-sm text-gray-500") { l(@invitation.created_at, format: :short) }
      td(class: "px-4 py-3 text-right") { actions }
    end
  end

  private

  def role_badge
    variant = case @invitation.role.to_s
    when "owner" then :destructive
    when "admin" then :secondary
    when "member" then :primary
    else :outline
    end

    render RubyUI::Badge::Badge.new(variant: variant) { @invitation.role.to_s.titleize }
  end

  def status_chip
    if @invitation.used?
      render RubyUI::Badge::Badge.new(variant: :secondary) { t("invitations.status.used", default: "Used") }
    elsif @invitation.expired?
      render RubyUI::Badge::Badge.new(variant: :destructive) { t("invitations.status.expired", default: "Expired") }
    else
      if @invitation.expires_at
        span do
          t("invitations.status.expires_in", default: "Expires %{time}", time: time_ago_in_words(@invitation.expires_at) + " #{t('ago', default: 'from now')}")
        end
      else
        render RubyUI::Badge::Badge.new(variant: :outline) { t("invitations.status.never_expires", default: "Never Expires") }
      end
    end
  end

  def actions
    if !@invitation.used? && policy(@invitation).destroy?
      render RubyUI::Button::Button.new(variant: :destructive) do
        link_to t("common.buttons.delete"),
                team_invitation_path(@team, @invitation),
                method: :delete,
                data: { confirm: t("invitations.index.revoke_confirm") }
      end
    end
  end
end
