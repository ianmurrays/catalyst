class Views::Teams::Index < Views::Base
  def initialize(teams:)
    @teams = teams
  end

  def page_title
    t("teams.index.title")
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
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold text-card-foreground") { t("teams.index.title") }
          p(class: "text-muted-foreground mt-1") { t("teams.index.subtitle") }
        end

        div(class: "flex gap-3") do
          link_to new_team_path, class: "inline-flex" do
            render RubyUI::Button::Button.new(variant: :primary) do
              t("teams.index.new_team")
            end
          end
        end
      end
    end
  end

  def content_section
    if @teams.any?
      teams_list
    else
      render Components::Teams::EmptyState.new
    end
  end

  def teams_list
    div(class: "space-y-4") do
      @teams.each do |team|
        render Components::Teams::TeamCard.new(team: team)
      end
    end
  end
end
