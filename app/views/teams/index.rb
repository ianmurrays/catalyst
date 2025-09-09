class Views::Teams::Index < Views::Base
  def initialize(teams:)
    @teams = teams
  end

  def page_title
    t("teams.index.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "flex items-center justify-between mb-8") do
      div do
        h1(class: "text-3xl font-bold text-gray-900") { t("teams.index.title") }
        p(class: "text-gray-600 mt-1") { t("teams.index.subtitle") }
      end

      div do
        render RubyUI::Button::Button.new(variant: :primary) do
          link_to t("teams.index.new_team"), new_team_path,
                  class: "flex items-center gap-2"
        end
      end
    end
  end

  def content_section
    if @teams.any?
      teams_grid
    else
      render Components::Teams::EmptyState.new
    end
  end

  def teams_grid
    div(class: "grid gap-6 md:grid-cols-2 lg:grid-cols-3") do
      @teams.each do |team|
        render Components::Teams::TeamCard.new(team: team)
      end
    end
  end
end
