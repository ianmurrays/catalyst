class Views::Teams::Show < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    @team.name
  end

  def view_template
    div(class: "container mx-auto px-4 py-8") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "flex items-center justify-between mb-8") do
      div do
        h1(class: "text-3xl font-bold text-gray-900") { @team.name }
        p(class: "text-gray-600 mt-1") do
          t("teams.show.member_count", count: @team.memberships.count)
        end
      end

      actions_section if can_manage_team?
    end
  end

  def actions_section
    div(class: "flex items-center gap-3") do
      render RubyUI::Button::Button.new(variant: :outline) do
        link_to t("teams.show.edit_team"), edit_team_path(@team)
      end

      # Invite Members (owners/admins)
      if policy(@team).update?
        render RubyUI::Button::Button.new(variant: :primary) do
          link_to t("teams.show.invite_members"), new_team_invitation_path(@team)
        end
      end

      if policy(@team).destroy?
        render RubyUI::Button::Button.new(variant: :destructive) do
          link_to t("teams.show.delete_team"), team_path(@team),
                  method: :delete,
                  data: { confirm: t("teams.form.confirm_delete") }
        end
      end
    end
  end

  def content_section
    div(class: "grid gap-8 lg:grid-cols-3") do
      main_content
      sidebar_content
    end
  end

  def main_content
    div(class: "lg:col-span-2 space-y-8") do
      team_info_section
      members_section
    end
  end

  def team_info_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("common.labels.name")
        end
      end

      render RubyUI::Card::CardContent.new do
        div(class: "space-y-4") do
          div do
            label(class: "block text-sm font-medium text-gray-700") do
              t("teams.form.name_label")
            end
            p(class: "mt-1 text-sm text-gray-900") { @team.name }
          end

          div do
            label(class: "block text-sm font-medium text-gray-700") do
              t("teams.form.slug_label")
            end
            p(class: "mt-1 text-sm text-gray-600") { @team.slug }
          end
        end
      end
    end
  end

  def members_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("teams.show.members")
        end
      end

      render RubyUI::Card::CardContent.new do
        render Components::Teams::MemberList.new(team: @team)
      end
    end
  end

  def sidebar_content
    div(class: "space-y-6") do
      team_stats_section
      recent_activity_section if @team.audits.exists?
    end
  end

  def team_stats_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          t("teams.show.settings")
        end
      end

      render RubyUI::Card::CardContent.new do
        div(class: "space-y-4 text-sm") do
          div do
            span(class: "font-medium") { t("activerecord.attributes.team.created_at") }
            br
            span(class: "text-gray-600") { l(@team.created_at, format: :long) }
          end

          if @team.updated_at != @team.created_at
            div do
              span(class: "font-medium") { t("activerecord.attributes.team.updated_at") }
              br
              span(class: "text-gray-600") { l(@team.updated_at, format: :long) }
            end
          end
        end
      end
    end
  end

  def recent_activity_section
    render RubyUI::Card::Card.new do
      render RubyUI::Card::CardHeader.new do
        render RubyUI::Card::CardTitle.new do
          "Recent Activity"
        end
      end

      render RubyUI::Card::CardContent.new do
        div(class: "space-y-2 text-sm") do
          @team.audits.order(created_at: :desc).limit(5).each do |audit|
            div(class: "flex justify-between items-center py-2 border-b border-gray-100 last:border-0") do
              span { audit.action.humanize }
              span(class: "text-gray-500") { time_ago_in_words(audit.created_at) + " ago" }
            end
          end
        end
      end
    end
  end

  def can_manage_team?
    policy(@team).update? || policy(@team).destroy?
  end
end
