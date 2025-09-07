# frozen_string_literal: true

class Views::Profile::Show < Views::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(user:)
    @user = user
  end

  def page_title
    "Profile - #{@user.name}"
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-4xl") do
      profile_header
      profile_overview_card
      div(class: "grid grid-cols-1 md:grid-cols-2 gap-6 mt-6") do
        profile_info_card
        preferences_card
      end
      account_info_card
    end
  end

  private

  def profile_header
    div(class: "bg-card border rounded-xl p-6 mb-6") do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-4") do
          render RubyUI::Avatar::Avatar.new(class: "w-16 h-16") do
            if @user.picture_url
              render RubyUI::Avatar::AvatarImage.new(
                src: @user.picture_url,
                alt: @user.name
              )
            end
            render RubyUI::Avatar::AvatarFallback.new do
              initials(@user.name)
            end
          end

          div do
            h1(class: "text-2xl font-bold text-card-foreground") { @user.name }
            p(class: "text-muted-foreground") { @user.email }
          end
        end

        div(class: "flex gap-3") do
          link_to "/profile/edit", class: "inline-flex" do
            render RubyUI::Button::Button.new(variant: :outline) do
              t("common.buttons.edit")
            end
          end
        end
      end
    end
  end

  def profile_overview_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.show.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.show.subtitle")
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field(t("activerecord.attributes.user.display_name"), @user.display_name || t("common.not_set"))
        profile_field(t("activerecord.attributes.user.bio"), @user.bio.present? ? @user.bio : t("common.not_set"))
      end
    end
  end


  def profile_info_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.show.contact_info.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.show.contact_info.description")
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field(t("activerecord.attributes.user.email"), @user.email)
        profile_field(t("activerecord.attributes.user.phone"), @user.phone || t("common.not_set"))
      end
    end
  end

  def preferences_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.show.preferences.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.show.preferences.description")
        end
      end

      render RubyUI::Card::CardContent.new do
        if @user.preferences.present?
          profile_field(t("common.labels.timezone"), @user.preferences.timezone || "UTC")
          profile_field(t("common.labels.language"), language_display_name(@user.preferences.language || "en"))
        else
          p(class: "text-muted-foreground") { t("common.no_preferences_set") }
        end
      end
    end
  end

  def account_info_card
    render RubyUI::Card::Card.new(class: "mt-6") do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { t("views.profile.show.account_info.title") }
        render RubyUI::Card::CardDescription.new do
          t("views.profile.show.account_info.description")
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field(t("views.profile.show.member_since_label"), l(@user.created_at, format: :long))
        profile_field(t("activerecord.attributes.user.updated_at"), l(@user.updated_at, format: :default))
        profile_field(t("activerecord.attributes.user.auth0_sub"), @user.auth0_sub)
      end
    end
  end

  def profile_field(label, value)
    div(class: "flex justify-between py-2 border-b border-border last:border-b-0") do
      span(class: "font-medium text-sm") { label }
      span(class: "text-sm text-muted-foreground truncate ml-4") { value }
    end
  end

  def initials(name)
    return "U" if name.blank?

    name.split.map { |part| part[0]&.upcase }.join[0..1]
  end

  def language_display_name(language_code)
    case language_code
    when "en"
      t("common.languages.english")
    when "es"
      t("common.languages.spanish")
    when "da"
      t("common.languages.danish")
    else
      language_code
    end
  end
end
