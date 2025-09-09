class Views::Teams::Edit < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    t("teams.edit.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      header_section
      form_section
    end
  end

  private

  def header_section
    div(class: "mb-8") do
      h1(class: "text-3xl font-bold text-gray-900") { t("teams.edit.title") }
      p(class: "text-gray-600 mt-1") { t("teams.edit.subtitle") }
    end
  end

  def form_section
    div(class: "max-w-2xl") do
      render Components::Teams::TeamForm.new(
        team: @team,
        url: team_path(@team),
        method: :patch,
        submit_text: t("teams.form.update_team")
      )
    end
  end
end
