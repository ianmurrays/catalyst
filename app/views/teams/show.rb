class Views::Teams::Show < Views::Base
  def initialize(team:)
    @team = team
  end

  def page_title
    @team.name
  end

  def view_template
    div(class: "container mx-auto px-4 py-8 max-w-4xl") do
      header_section
      content_section
    end
  end

  private

  def header_section
    div(class: "bg-card border rounded-xl p-6 mb-6") do
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold text-card-foreground") { @team.name }
          p(class: "text-muted-foreground mt-1") do
            t("teams.show.member_count", count: @team.memberships.count)
          end
        end

        actions_section if can_manage_team?
      end
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
    div(class: "grid grid-cols-1 lg:grid-cols-3 gap-6") do
      main_content
      sidebar_content
    end
  end

  def main_content
    div(class: "lg:col-span-2 space-y-6") do
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
          team_field(t("teams.form.name_label"), @team.name)
          team_field(t("teams.form.slug_label"), @team.slug)
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
        div(class: "space-y-4") do
          team_field(t("activerecord.attributes.team.created_at"), l(@team.created_at, format: :long))

          if @team.updated_at != @team.created_at
            team_field(t("activerecord.attributes.team.updated_at"), l(@team.updated_at, format: :long))
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
        div(class: "space-y-2") do
          @team.audits.order(created_at: :desc).limit(5).each do |audit|
            div(class: "flex justify-between py-2 border-b border-border last:border-b-0") do
              span(class: "text-sm font-medium") { audit.action.humanize }
              span(class: "text-sm text-muted-foreground") { time_ago_in_words(audit.created_at) + " ago" }
            end
          end
        end
      end
    end
  end

  def can_manage_team?
    policy(@team).update? || policy(@team).destroy?
  end

  def team_field(label, value)
    div(class: "flex justify-between py-2 border-b border-border last:border-b-0") do
      span(class: "font-medium text-sm") { label }
      span(class: "text-sm text-muted-foreground truncate ml-4") { value }
    end
  end
end
