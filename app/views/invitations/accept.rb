# frozen_string_literal: true

class Views::Invitations::Accept < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    t("invitations.new.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-12") do
      render RubyUI::Card::Card.new do
        render RubyUI::Card::CardHeader.new do
          render RubyUI::Card::CardTitle.new do
            t("invitations.flash.accepted")
          end

          render RubyUI::Card::CardDescription.new do
            t("invitations.accept.description", default: "You have successfully joined %{team}.").gsub("%{team}", @team.name.to_s)
          end
        end

        render RubyUI::Card::CardContent.new do
          div(class: "flex items-center gap-3") do
            render RubyUI::Button::Button.new(variant: :primary) do
              link_to t("teams.show.edit_team"), team_path(@team)
            end
          end
        end
      end
    end
  end
end
