class Components::Teams::TeamForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo

  def initialize(team:, url:, method:, submit_text:)
    @team = team
    @url = url
    @method = method
    @submit_text = submit_text
  end

  def view_template
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardContent.new do
        form_with(
          model: @team,
          url: @url,
          method: @method,
          class: "space-y-6"
        ) do |form|
          render_form_fields(form)
          render_form_actions
        end
      end
    end
  end

  private

  def render_form_fields(form)
    div(class: "space-y-4") do
      # Display validation errors if any
      if @team.errors.any?
        validation_errors_section
      end

      # Team name field
      div do
        label(class: "block text-sm font-medium text-gray-700 mb-1", for: "team_name") do
          t("teams.form.name_label")
        end

        render RubyUI::Input::Input.new(
          id: "team_name",
          name: "team[name]",
          value: @team.name,
          placeholder: t("teams.form.name_placeholder"),
          required: true,
          class: error_class_for(:name)
        )

        if @team.errors[:name].any?
          div(class: "mt-1 text-sm text-red-600") do
            @team.errors[:name].first
          end
        end
      end

      # Auto-generated slug display
      if @team.persisted?
        div do
          label(class: "block text-sm font-medium text-gray-700 mb-1") do
            t("teams.form.slug_label")
          end

          render RubyUI::Input::Input.new(
            value: @team.slug,
            disabled: true,
            class: "bg-gray-50 text-gray-500"
          )

          p(class: "mt-1 text-xs text-gray-500") do
            t("teams.form.slug_help")
          end
        end
      end
    end
  end

  def render_form_actions
    div(class: "flex items-center justify-between pt-4") do
      render RubyUI::Button::Button.new(variant: :outline, type: "button") do
        link_to t("teams.form.cancel"),
                @team.persisted? ? team_path(@team) : teams_path,
                class: "w-full"
      end

      render RubyUI::Button::Button.new(variant: :primary, type: "submit") do
        @submit_text
      end
    end
  end

  def validation_errors_section
    render RubyUI::Alert::Alert.new(variant: :destructive, class: "mb-4") do
      render RubyUI::Alert::AlertTitle.new do
        t("views.profile.edit.validation_errors")
      end

      render RubyUI::Alert::AlertDescription.new do
        ul(class: "mt-2 list-disc list-inside") do
          @team.errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end

  def error_class_for(field)
    if @team.errors[field].any?
      "border-red-500 focus:border-red-500 focus:ring-red-500"
    else
      ""
    end
  end
end
