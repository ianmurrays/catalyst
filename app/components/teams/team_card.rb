class Components::Teams::TeamCard < Components::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  def initialize(team:)
    @team = team
  end

  def view_template
    render RubyUI::Card::Card.new(class: "hover:shadow-lg transition-shadow cursor-pointer") do
      link_to team_path(@team), class: "block" do
        card_content
      end
    end
  end

  private

  def card_content
    render RubyUI::Card::CardContent.new(class: "p-4") do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-3 flex-1") do
          team_avatar
          team_info
          team_stats
        end

        user_role_badge
      end
    end
  end

  def team_avatar
    render RubyUI::Avatar::Avatar.new(class: "w-10 h-10") do
      render RubyUI::Avatar::AvatarFallback.new do
        @team.name[0..1].upcase
      end
    end
  end

  def team_info
    div do
      h3(class: "font-semibold text-card-foreground text-lg") { @team.name }
      p(class: "text-sm text-muted-foreground") do
        "@#{@team.slug}"
      end
    end
  end

  def user_role_badge
    user_role = @team.member_role(current_user)
    return unless user_role

    render RubyUI::Badge::Badge.new(
      variant: badge_variant_for_role(user_role),
      class: "text-xs"
    ) do
      user_role.to_s.humanize
    end
  end

  def team_stats
    div(class: "flex items-center gap-4 text-sm text-muted-foreground ml-auto mr-4") do
      div(class: "flex items-center gap-1") do
        span(class: "text-muted-foreground") { "Members:" }
        span do
          @team.memberships.count.to_s
        end
      end

      div(class: "flex items-center gap-1") do
        span(class: "text-muted-foreground") { "Created:" }
        span do
          time_ago_in_words(@team.created_at) + " ago"
        end
      end
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
end
