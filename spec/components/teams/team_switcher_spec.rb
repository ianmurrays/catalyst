# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Components::Teams::TeamSwitcher, type: :component do
  include AuthHelpers

  let(:user) { create(:user) }
  let(:team1) { create(:team, name: "Design Team") }
  let(:team2) { create(:team, name: "Development Team") }
  let(:teams) { [ team1, team2 ] }

  before do
    create(:membership, :admin, user: user, team: team1)
    create(:membership, :member, user: user, team: team2)
  end

  describe "rendering" do
    it "renders team selector with available teams" do
      component = described_class.new(
        current_team: team1,
        available_teams: teams,
        show_role_badges: true
      )

      rendered = render_with_view_context(component)
      doc = Nokogiri::HTML5(rendered)

      expect(doc.css('[data-controller*="teams--team-switcher"]')).not_to be_empty
      expect(rendered).to include("Design Team")
      expect(rendered).to include("Development Team")
    end

    it "shows role badges when enabled" do
      component = described_class.new(
        current_team: team1,
        available_teams: teams,
        show_role_badges: true
      )

      # Mock the user role lookup method
      allow(component).to receive(:user_role_for_team).with(team1).and_return('admin')
      allow(component).to receive(:user_role_for_team).with(team2).and_return('member')

      rendered = render_with_view_context(component)
      expect(rendered).to include(t("teams.roles.admin"))
      expect(rendered).to include(t("teams.roles.member"))
    end

    it "renders mobile layout when mobile flag is true" do
      component = described_class.new(
        current_team: team1,
        available_teams: teams,
        mobile: true
      )

      rendered = render_with_view_context(component)
      doc = Nokogiri::HTML5(rendered)

      expect(doc.css('.w-full')).not_to be_empty
    end

    it "displays current team with indicator" do
      component = described_class.new(
        current_team: team1,
        available_teams: teams
      )

      rendered = render_with_view_context(component)
      doc = Nokogiri::HTML5(rendered)

      # Should show current team in trigger
      expect(rendered).to include("Design Team")

      # Should have current indicator (checkmark)
      expect(doc.css('svg[viewBox="0 0 24 24"]')).not_to be_empty
    end
  end

  describe "edge cases" do
    it "renders no teams message when no teams available" do
      component = described_class.new(available_teams: [])

      rendered = render_with_view_context(component)
      expect(rendered).to include(t("teams.no_teams_available"))
    end

    it "renders single team without selector" do
      component = described_class.new(
        current_team: team1,
        available_teams: [ team1 ]
      )

      rendered = render_with_view_context(component)
      expect(rendered).to include("Design Team")
      # Should not render the full select component
      expect(rendered).not_to include("data-controller")
    end

    it "handles long team names on mobile" do
      long_name_team = create(:team, name: "Very Long Team Name That Should Be Truncated")
      component = described_class.new(
        current_team: long_name_team,
        available_teams: [ long_name_team ],
        mobile: true
      )

      rendered = render_with_view_context(component)
      expect(rendered).to include("Very Long Tea...")
    end
  end

  describe "component props" do
    it "accepts size parameter" do
      component = described_class.new(
        current_team: team1,
        available_teams: teams,
        size: :lg
      )

      rendered = render_with_view_context(component)
      doc = Nokogiri::HTML5(rendered)

      # Should have large size classes
      expect(doc.css('.h-12')).not_to be_empty
    end

    it "handles missing current_team gracefully" do
      component = described_class.new(
        available_teams: teams
      )

      rendered = render_with_view_context(component)
      expect(rendered).to include(t("teams.no_team"))
    end
  end

  private

  def t(key, **options)
    case key.to_s
    when "teams.roles.admin"
      "Admin"
    when "teams.roles.member"
      "Member"
    when "teams.no_teams_available"
      "No teams available"
    when "teams.no_team"
      "No team selected"
    else
      key.to_s
    end
  end
end
