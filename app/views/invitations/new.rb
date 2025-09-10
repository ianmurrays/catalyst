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
    div(class: "container mx-auto px-4 py-8 max-w-4xl") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "bg-card border rounded-xl p-6 mb-6") do
      h1(class: "text-2xl font-bold text-card-foreground") { t("invitations.new.title") }
      p(class: "text-muted-foreground mt-1") { t("invitations.new.subtitle", default: "Invite new members to join your team") }
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
          div(class: "mt-6 border-t border-border pt-6") do
            h2(class: "text-lg font-semibold text-card-foreground mb-2") { t("invitations.new.share_title", default: "Share this link") }
            render Components::Invitations::ShareLink.new(url: @generated_url)
          end
        end
      end
    end
  end
end
