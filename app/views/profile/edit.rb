# frozen_string_literal: true

class Views::Profile::Edit < Views::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(user:, errors: nil)
    @user = user
    @errors = errors || {}
  end

  def page_title
    t("views.profile.edit.title")
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-4xl") do
      page_header

      if @errors.any?
        error_alert
      end

      form_with(model: @user, url: "/profile", method: :patch, local: true, class: "space-y-6") do |form|
        div(class: "grid grid-cols-1 lg:grid-cols-2 gap-6") do
          basic_info_section(form)
          contact_info_section(form)
        end

        preferences_section(form)

        form_actions(form)
      end
    end
  end

  private

  def page_header
    div(class: "flex items-center justify-between mb-8") do
      div do
        h1(class: "text-3xl font-bold text-foreground") { t("views.profile.edit.title") }
        p(class: "text-muted-foreground mt-2") do
          t("views.profile.edit.subtitle")
        end
      end

      link_to "/profile", class: "inline-flex" do
        render RubyUI::Button::Button.new(variant: :outline) do
          t("common.buttons.cancel")
        end
      end
    end
  end

  def error_alert
    render RubyUI::Alert::Alert.new(variant: :destructive, class: "mb-6") do
      render RubyUI::Alert::AlertTitle.new { t("views.profile.edit.validation_errors") }
      render RubyUI::Alert::AlertDescription.new do
        ul(class: "list-disc list-inside space-y-1") do
          @errors.full_messages.each do |message|
            li { message }
          end
        end
      end
    end
  end


  def basic_info_section(form)
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.edit.basic_info.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.edit.basic_info.description")
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        form_field(form, :display_name, t("activerecord.attributes.user.display_name"), t("views.profile.edit.display_name_hint"))
        form_field(form, :bio, t("activerecord.attributes.user.bio"), t("views.profile.edit.bio_hint"), type: :textarea)
      end
    end
  end

  def contact_info_section(form)
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.edit.contact_info.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.edit.contact_info.description")
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        readonly_field(t("activerecord.attributes.user.email"), @user.email, t("views.profile.edit.email_readonly_note"))
        form_field(form, :phone, t("activerecord.attributes.user.phone"), t("views.profile.edit.phone_hint"))
      end
    end
  end

  def preferences_section(form)
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.edit.preferences.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.edit.preferences.description")
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        timezone_field(form)
        preferences_field(form, "language", t("common.labels.language"), language_options)
      end
    end
  end


  def form_actions(form)
    div(class: "flex items-center justify-between pt-6 border-t border-border") do
      div(class: "text-sm text-muted-foreground") do
        t("views.profile.edit.changes_note")
      end

      div(class: "flex gap-3") do
        link_to "/profile", class: "inline-flex" do
          render RubyUI::Button::Button.new(variant: :outline) do
            t("common.buttons.cancel")
          end
        end

        render RubyUI::Button::Button.new(
          type: :submit
        ) do
          t("common.buttons.save_changes")
        end
      end
    end
  end

  def form_field(form, field, label, hint = nil, type: :input)
    div(class: "space-y-2") do
      label(for: "user_#{field}", class: "text-sm font-medium") { label }

      if type == :textarea
        render RubyUI::Textarea::Textarea.new(
          name: "user[#{field}]",
          id: "user_#{field}",
          placeholder: hint,
          rows: 3,
          class: error_class(field)
        ) do
          @user.send(field)
        end
      else
        render RubyUI::Input::Input.new(
          name: "user[#{field}]",
          id: "user_#{field}",
          value: @user.send(field),
          placeholder: hint,
          class: error_class(field)
        )
      end

      if hint
        p(class: "text-sm text-muted-foreground") { hint }
      end

      if @errors[field]&.any?
        p(class: "text-sm text-destructive") { @errors[field].first }
      end
    end
  end

  def readonly_field(label, value, hint = nil)
    div(class: "space-y-2") do
      label(class: "text-sm font-medium") { label }
      div(class: "px-3 py-2 border border-border rounded-md bg-muted text-muted-foreground") do
        value
      end
      if hint
        p(class: "text-sm text-muted-foreground") { hint }
      end
    end
  end

  def preferences_field(form, key, label, options)
    current_value = case key
    when "language"
                      @user.preferences&.language || options.first
    when "timezone"
                      @user.preferences&.timezone || options.first
    else
                      options.first
    end

    div(class: "space-y-2") do
      label(for: "user_preferences_#{key}", class: "text-sm font-medium") { label }
      select(
        name: "user[preferences][#{key}]",
        id: "user_preferences_#{key}",
        class: "w-full px-3 py-2 border border-border rounded-md bg-background"
      ) do
        options.each do |option|
          option_value = option.is_a?(Array) ? option[1] : option
          option_text = option.is_a?(Array) ? option[0] : option.humanize

          option_tag(
            option_text,
            value: option_value,
            selected: current_value == option_value
          )
        end
      end
    end
  end

  def language_options
    @user.available_languages
  end

  def timezone_options
    TimezoneService.timezone_options
  end

  def timezone_field(form)
    current_value = @user.preferences&.timezone || timezone_options.first[1]

    div(class: "space-y-2", data: {
      controller: "timezone-detector",
      timezone_detector_detected_text_value: t("timezones.detected", timezone: "%{timezone}"),
      timezone_detector_use_this_text_value: t("timezones.use_this"),
      timezone_detector_dismiss_text_value: t("timezones.dismiss")
    }) do
      label(for: "user_preferences_timezone", class: "text-sm font-medium") do
        t("common.labels.timezone")
      end

      # Suggestion area (initially hidden)
      div(
        data: { timezone_detector_target: "suggestion" },
        class: "hidden mb-2"
      )

      # HTML template for timezone suggestion
      template(data: { timezone_detector_target: "template" }) do
        div(class: "flex items-center justify-between p-3 bg-muted border border-border rounded-md") do
          div(class: "flex items-center space-x-2") do
            render Components::Icons::Info.new(size: :sm, class: "text-muted-foreground")
            span(class: "text-sm text-foreground", data: { timezone_detector_target: "detectedText" }) do
              # Placeholder text - will be replaced by JavaScript
            end
          end
          div(class: "flex space-x-2") do
            button(
              type: "button",
              data: {
                action: "click->timezone-detector#acceptSuggestion",
                timezone_detector_target: "acceptButton"
              },
              class: "text-sm text-primary hover:text-primary/80 font-medium"
            ) do
              # Button text will be set by JavaScript
            end
            button(
              type: "button",
              data: { action: "click->timezone-detector#dismissSuggestion" },
              class: "text-sm text-muted-foreground hover:text-foreground",
              data: { timezone_detector_target: "dismissButton" }
            ) do
              # Button text will be set by JavaScript
            end
          end
        end
      end

      select(
        name: "user[preferences][timezone]",
        id: "user_preferences_timezone",
        data: { timezone_detector_target: "select" },
        class: "w-full px-3 py-2 border border-border rounded-md bg-background"
      ) do
        timezone_options.each do |option|
          option_value = option.is_a?(Array) ? option[1] : option
          option_text = option.is_a?(Array) ? option[0] : option.humanize

          option_tag(
            option_text,
            value: option_value,
            selected: current_value == option_value
          )
        end
      end
    end
  end

  def error_class(field)
    @errors[field]&.any? ? "border-destructive" : ""
  end

  def option_tag(text, value:, selected: false)
    option(value: value, selected: selected) { text }
  end
end
