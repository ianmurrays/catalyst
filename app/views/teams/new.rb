class Views::Teams::New < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    t("teams.new.title")
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
      h1(class: "text-3xl font-bold text-gray-900") { t("teams.new.title") }
      p(class: "text-gray-600 mt-1") { t("teams.new.subtitle") }
    end
  end

  def form_section
    div(class: "max-w-2xl") do
      render Components::Teams::TeamForm.new(
        team: @team,
        url: teams_path,
        method: :post,
        submit_text: t("teams.form.create_team")
      )
    end
  end
end
