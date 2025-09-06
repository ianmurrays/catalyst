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
              "Edit Profile"
            end
          end
        end
      end
    end
  end

  def profile_overview_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Profile Overview" }
        render RubyUI::Card::CardDescription.new do
          "Your basic information and bio"
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field("Display Name", @user.display_name || "Not set")
        profile_field("Bio", @user.bio.present? ? @user.bio : "Not set")
      end
    end
  end


  def profile_info_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Contact Information" }
        render RubyUI::Card::CardDescription.new do
          "Your contact details and links"
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field("Email", @user.email)
        profile_field("Phone", @user.phone || "Not set")
      end
    end
  end

  def preferences_card
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Preferences" }
        render RubyUI::Card::CardDescription.new do
          "Your account preferences and settings"
        end
      end

      render RubyUI::Card::CardContent.new do
        if @user.preferences.present?
          profile_field("Timezone", @user.preferences.dig("timezone") || "UTC")
          profile_field("Language", @user.preferences.dig("language") || "English")
        else
          p(class: "text-muted-foreground") { "No preferences set" }
        end
      end
    end
  end

  def account_info_card
    render RubyUI::Card::Card.new(class: "mt-6") do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new { "Account Information" }
        render RubyUI::Card::CardDescription.new do
          "Read-only account details"
        end
      end

      render RubyUI::Card::CardContent.new do
        profile_field("Member since", @user.created_at.strftime("%B %d, %Y"))
        profile_field("Last updated", @user.updated_at.strftime("%B %d, %Y at %I:%M %p"))
        profile_field("Authentication Provider ID", @user.auth0_sub)
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
end
