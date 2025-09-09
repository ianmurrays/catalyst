class Components::Teams::EmptyState < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def view_template
    div(class: "text-center py-16") do
      empty_state_icon
      empty_state_content
      empty_state_actions
    end
  end

  private

  def empty_state_icon
    div(class: "mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-6") do
      # Team icon (using emoji for simplicity)
      span(class: "text-4xl text-gray-400") { "👥" }
    end
  end

  def empty_state_content
    div(class: "mb-8") do
      h2(class: "text-xl font-semibold text-gray-900 mb-2") do
        t("teams.index.empty_state")
      end

      p(class: "text-gray-600 max-w-sm mx-auto") do
        t("teams.index.empty_description")
      end
    end
  end

  def empty_state_actions
    div(class: "flex justify-center") do
      render RubyUI::Button::Button.new(variant: :primary) do
        link_to t("teams.index.new_team"), new_team_path,
                class: "flex items-center gap-2"
      end
    end
  end
end
