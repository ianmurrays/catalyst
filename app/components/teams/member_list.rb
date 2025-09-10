class Components::Teams::MemberList < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(team:)
    @team = team
  end

  def view_template
    if @team.memberships.any?
      members_list
    else
      empty_members_state
    end
  end

  private

  def members_list
    div(class: "space-y-3") do
      @team.memberships.includes(:user).order(:created_at).each do |membership|
        member_row(membership)
      end
    end
  end

  def member_row(membership)
    div(class: "flex items-center justify-between p-3 border border-border rounded-lg") do
      div(class: "flex items-center gap-3") do
        member_avatar(membership.user)
        member_info(membership)
      end

      member_actions(membership)
    end
  end

  def member_avatar(user)
    render RubyUI::Avatar::Avatar.new(class: "w-8 h-8") do
      if user.picture_url
        render RubyUI::Avatar::AvatarImage.new(
          src: user.picture_url,
          alt: user.display_name
        )
      end
      render RubyUI::Avatar::AvatarFallback.new do
        user.display_name[0..1].upcase
      end
    end
  end

  def member_info(membership)
    div do
      div(class: "flex items-center gap-2") do
        span(class: "font-medium text-card-foreground") { membership.user.display_name }

        render RubyUI::Badge::Badge.new(
          variant: badge_variant_for_role(membership.role),
          class: "text-xs"
        ) do
          membership.role.humanize
        end
      end

      p(class: "text-sm text-muted-foreground") { membership.user.email }

      p(class: "text-xs text-muted-foreground") do
        "#{t('activerecord.attributes.membership.created_at')}: #{l(membership.created_at, format: :short)}"
      end
    end
  end

  def member_actions(membership)
    # Only show actions if current user can manage the team
    return unless can_manage_members?

    div(class: "flex items-center gap-2") do
      # Don't show remove action for owners or if it's the current user and they're the only owner
      unless membership.owner? || (membership.user == current_user && @team.owners.count == 1)
        render RubyUI::Button::Button.new(
          variant: :outline,
          size: :sm,
          class: "text-destructive hover:text-destructive hover:bg-destructive/10"
        ) do
          t("common.buttons.remove")
        end
      end
    end
  end

  def empty_members_state
    div(class: "text-center py-8 text-muted-foreground") do
      p { t("teams.members.empty_state") }
    end
  end

  def badge_variant_for_role(role)
    case role.to_s
    when "owner"
      :default
    when "admin"
      :secondary
    when "member"
      :outline
    when "viewer"
      :secondary
    else
      :outline
    end
  end

  def can_manage_members?
    @team.admin?(current_user) || @team.owner?(current_user)
  end
end
