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
    div(class: "flex items-center justify-between p-3 border border-gray-200 rounded-lg") do
      div(class: "flex items-center gap-3") do
        member_avatar(membership.user)
        member_info(membership)
      end

      member_actions(membership)
    end
  end

  def member_avatar(user)
    div(class: "w-8 h-8 bg-gradient-to-br from-green-400 to-blue-500 rounded-full flex items-center justify-center") do
      span(class: "text-white text-xs font-medium") do
        user.display_name[0..1].upcase
      end
    end
  end

  def member_info(membership)
    div do
      div(class: "flex items-center gap-2") do
        span(class: "font-medium text-gray-900") { membership.user.display_name }

        render RubyUI::Badge::Badge.new(
          variant: badge_variant_for_role(membership.role),
          class: "text-xs"
        ) do
          membership.role.humanize
        end
      end

      p(class: "text-sm text-gray-600") { membership.user.email }

      p(class: "text-xs text-gray-500") do
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
          class: "text-red-600 hover:text-red-700 hover:bg-red-50"
        ) do
          "Remove"
        end
      end
    end
  end

  def empty_members_state
    div(class: "text-center py-8 text-gray-500") do
      p { "No members yet" }
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
