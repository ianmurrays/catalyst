# frozen_string_literal: true

class Views::Invitations::Index < Views::Base
  def initialize(team:, invitations:, status: "active")
    @team = team
    @invitations = invitations
    @status = status.presence || "active"
  end

  def page_title
    t("invitations.index.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "flex items-center justify-between mb-6") do
      div do
        h1(class: "text-2xl font-bold text-gray-900") { t("invitations.index.title") }
      end

      if policy(@team).update?
        render RubyUI::Button::Button.new(variant: :primary) do
          link_to t("invitations.new.title"),
                  new_team_invitation_path(@team)
        end
      end
    end
  end

  def content_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        filter_tabs
      end

      render RubyUI::Card::CardContent.new do
        if @invitations.any?
          table(class: "min-w-full divide-y divide-gray-200") do
            thead(class: "bg-gray-50") do
              tr do
                th(class: thc) { t("activerecord.attributes.invitation.role") }
                th(class: thc) { t("invitations.index.created_by", default: "Created By") }
                th(class: thc) { t("invitations.index.status", default: "Status") }
                th(class: thc) { t("activerecord.attributes.invitation.created_at") }
                th(class: "px-4 py-3 text-right text-xs font-medium uppercase tracking-wider text-gray-500") { t("common.labels.actions", default: "Actions") }
              end
            end

            tbody(class: "divide-y divide-gray-200") do
              @invitations.each do |invitation|
                render Components::Invitations::InvitationRow.new(invitation:, team: @team)
              end
            end
          end
        else
          div(class: "text-sm text-gray-500") { t("invitations.index.empty_state", default: "No invitations found.") }
        end
      end
    end
  end

  def filter_tabs
    div(class: "flex items-center gap-2") do
      tab_link t("invitations.index.active_tab"), status: "active"
      tab_link t("invitations.index.used_tab"), status: "used"
    end
  end

  def tab_link(label, status:)
    active = (@status == status)
    render RubyUI::Button::Button.new(variant: active ? :secondary : :outline) do
      link_to label, team_invitations_path(@team, status:)
    end
  end

  def thc
    "px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500"
  end
end
