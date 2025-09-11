class Views::Onboarding::Show < Views::Base
  def initialize(can_create_teams:, team: nil)
    @can_create_teams = can_create_teams
    @team = team
  end

  def page_title
    t("onboarding.welcome.title", app_name: t("application.name"), name: current_user.name)
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-2xl") do
      welcome_section
      if @can_create_teams
        team_creation_section
      else
        waiting_section
      end
    end
  end

  private

  def welcome_section
    div(class: "text-center mb-8") do
      h1(class: "text-4xl font-bold mb-4") do
        t("onboarding.welcome.title", app_name: t("application.name"), name: current_user.name)
      end
      p(class: "text-lg text-muted-foreground") do
        t("onboarding.welcome.subtitle")
      end
    end
  end

  def team_creation_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("onboarding.create_team.heading")
        end
        render RubyUI::Card::CardDescription.new do
          t("onboarding.create_team.description")
        end
      end

      render RubyUI::Card::CardContent.new do
        team_form
      end
    end
  end

  def team_form
    form_with url: onboarding_create_team_path, local: true, class: "space-y-4" do |form|
      div do
        label(class: "block text-sm font-medium mb-2", for: "team_name") do
          t("teams.form.name_label")
        end
        form.text_field :name,
          placeholder: t("teams.form.name_placeholder"),
          value: @team&.name,
          class: "w-full px-3 py-2 border border-input rounded-md focus:outline-none focus:ring-2 focus:ring-ring"

        if @team&.errors&.[](:name)&.any?
          div(class: "text-sm text-destructive mt-1") do
            @team.errors[:name].first
          end
        end
      end

      div(class: "flex gap-2") do
        render RubyUI::Button::Button.new(type: :submit, variant: :primary) do
          t("onboarding.create_team.button")
        end

        render RubyUI::Button::Button.new(variant: :outline) do
          link_to t("onboarding.create_team.skip"), teams_path
        end
      end
    end
  end

  def waiting_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("onboarding.waiting.title")
        end
      end

      render RubyUI::Card::CardContent.new do
        div(class: "text-center space-y-4") do
          p(class: "text-muted-foreground") do
            t("onboarding.waiting.message")
          end
          p(class: "text-sm") do
            t("onboarding.waiting.contact")
          end

          render RubyUI::Button::Button.new(variant: :outline) do
            link_to t("onboarding.waiting.check_again"), onboarding_path
          end
        end
      end
    end
  end
end
