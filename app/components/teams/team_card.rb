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
    render RubyUI::Card::CardHeader.new do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-3") do
          team_avatar
          team_info
        end

        user_role_badge
      end
    end

    render RubyUI::Card::CardContent.new do
      team_stats
    end
  end

  def team_avatar
    div(class: "w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center") do
      span(class: "text-white font-semibold") do
        @team.name[0..1].upcase
      end
    end
  end

  def team_info
    div do
      h3(class: "font-semibold text-gray-900 text-lg") { @team.name }
      p(class: "text-sm text-gray-600") do
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
    div(class: "flex items-center justify-between text-sm text-gray-600") do
      div(class: "flex items-center gap-4") do
        div(class: "flex items-center gap-1") do
          # Users icon (using simple text for now)
          span(class: "text-gray-400") { "👥" }
          span do
            t("teams.show.member_count", count: @team.memberships.count)
          end
        end

        div(class: "flex items-center gap-1") do
          # Calendar icon
          span(class: "text-gray-400") { "📅" }
          span do
            time_ago_in_words(@team.created_at) + " ago"
          end
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
