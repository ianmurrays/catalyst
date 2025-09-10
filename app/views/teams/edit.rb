class Views::Teams::Edit < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    t("teams.edit.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-4xl") do
      form_section
    end
  end

  private

  def form_section
    div(class: "max-w-2xl mx-auto") do
      render Components::Teams::TeamForm.new(
        team: @team,
        url: team_path(@team),
        method: :patch,
        submit_text: t("teams.form.update_team")
      )
    end
  end
end
