# frozen_string_literal: true

class Views::Profile::Edit < Views::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(user:, errors: nil)
    @user = user
    @errors = errors || {}
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
        h1(class: "text-3xl font-bold text-foreground") { "Edit Profile" }
        p(class: "text-muted-foreground mt-2") do
          "Update your profile information and preferences"
        end
      end

      link_to "/profile", class: "inline-flex" do
        render RubyUI::Button::Button.new(variant: :outline) do
          "Cancel"
        end
      end
    end
  end

  def error_alert
    render RubyUI::Alert::Alert.new(variant: :destructive, class: "mb-6") do
      render RubyUI::Alert::AlertTitle.new { "Validation Errors" }
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
        render RubyUI::Card::CardTitle.new { "Basic Information" }
        render RubyUI::Card::CardDescription.new do
          "Your public profile information"
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        form_field(form, :display_name, "Display Name", "Your public display name")
        form_field(form, :bio, "Bio", "Tell others about yourself", type: :textarea)
      end
    end
  end

  def contact_info_section(form)
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Contact Information" }
        render RubyUI::Card::CardDescription.new do
          "Your contact details (private)"
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        if @user.auth0_email?
          readonly_field("Email", @user.email, "This email is provided by Auth0 and cannot be changed")
        else
          form_field(form, :email, "Email", "Your email address")
        end
        form_field(form, :phone, "Phone Number", "Your phone number with country code")
      end
    end
  end

  def preferences_section(form)
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Preferences" }
        render RubyUI::Card::CardDescription.new do
          "Customize your experience"
        end
      end

      render RubyUI::Card::CardContent.new(class: "space-y-4") do
        preferences_field(form, "timezone", "Timezone", timezone_options)
        preferences_field(form, "language", "Language", [ [ "English", "en" ], [ "Spanish", "es" ] ])
      end
    end
  end


  def form_actions(form)
    div(class: "flex items-center justify-between pt-6 border-t border-border") do
      div(class: "text-sm text-muted-foreground") do
        "Changes will be saved immediately"
      end

      div(class: "flex gap-3") do
        link_to "/profile", class: "inline-flex" do
          render RubyUI::Button::Button.new(variant: :outline) do
            "Cancel"
          end
        end

        render RubyUI::Button::Button.new(
          type: :submit
        ) do
          "Save Changes"
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
          value: @user.send(field),
          placeholder: hint,
          rows: 3,
          class: error_class(field)
        )
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
    current_value = @user.preferences&.dig(key) || options.first

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

  def timezone_options
    [
      [ "UTC", "UTC" ],
      [ "Eastern Time", "America/New_York" ],
      [ "Central Time", "America/Chicago" ],
      [ "Mountain Time", "America/Denver" ],
      [ "Pacific Time", "America/Los_Angeles" ],
      [ "London", "Europe/London" ],
      [ "Paris", "Europe/Paris" ],
      [ "Tokyo", "Asia/Tokyo" ]
    ]
  end

  def error_class(field)
    @errors[field]&.any? ? "border-destructive" : ""
  end

  def option_tag(text, value:, selected: false)
    option(value: value, selected: selected) { text }
  end
end
