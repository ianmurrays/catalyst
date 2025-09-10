# frozen_string_literal: true

class Views::Invitations::New < Views::Base
  def initialize(team:, invitation:, generated_url: nil)
    @team = team
    @invitation = invitation
    @generated_url = generated_url
  end

  def page_title
    t("invitations.new.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "mb-8") do
      h1(class: "text-3xl font-bold text-gray-900") { t("invitations.new.title") }
      p(class: "text-gray-600 mt-1") { t("invitations.new.subtitle", default: "Invite new members to join your team") }
    end
  end

  def content_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("invitations.new.title")
        end
      end

      render RubyUI::Card::CardContent.new do
        render Components::Invitations::InvitationForm.new(
          team: @team,
          invitation: @invitation,
          url: team_invitations_path(@team),
          method: :post,
          submit_text: t("invitations.new.generate_button")
        )

        if @generated_url.present?
          div(class: "mt-6 border-t pt-6") do
            h2(class: "text-lg font-semibold mb-2") { t("invitations.new.share_title", default: "Share this link") }
            render Components::Invitations::ShareLink.new(url: @generated_url)
          end
        end
      end
    end
  end
end
