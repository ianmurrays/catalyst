# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamsHelper, type: :helper do
  let(:user) { create(:user) }
  let(:team1) { create(:team, name: "Alpha") }
  let(:team2) { create(:team, name: "Beta") }

  before do
    create(:membership, user: user, team: team1, role: :owner)
    create(:membership, user: user, team: team2, role: :member)
  end

  # Provide current_user/current_team in helper context for tests
  before do
    mod = Module.new do
      attr_accessor :__current_team, :__current_user
      def current_team = @__current_team
      def current_user = @__current_user
    end
    helper.extend(mod)
  end

  describe "#current_team_name" do
    it "returns the current team name when present" do
      helper.__current_team = team1
      expect(helper.current_team_name).to eq("Alpha")
    end

    it "returns i18n fallback when no current team" do
      helper.__current_team = nil
      expect(helper.current_team_name).to eq(I18n.t("teams.no_team"))
    end
  end

  describe "#user_teams_for_select" do
    it "returns label-value pairs for user's teams" do
      helper.__current_user = user

      result = helper.user_teams_for_select

      expect(result).to include([ "Alpha", team1.id ])
      expect(result).to include([ "Beta", team2.id ])
    end

    it "returns empty array when no current_user" do
      helper.__current_user = nil

      expect(helper.user_teams_for_select).to eq([])
    end
  end

  describe "#team_role_badge" do
    it "returns the current user's role for a given team" do
      helper.__current_user = user

      expect(helper.team_role_badge(team1)).to eq("owner")
      expect(helper.team_role_badge(team2)).to eq("member")
    end

    it "returns nil when user or team is missing" do
      helper.__current_user = nil
      expect(helper.team_role_badge(team1)).to be_nil
    end
  end

  # Essential helper methods for Phase 5 implementation
  describe "#team_avatar" do
    it "returns team initial in a styled container by default" do
      result = helper.team_avatar(team1)

      expect(result).to include("A") # team initial
      expect(result).to include("rounded-full") # styling
      expect(result).to include("bg-primary") # background
    end

    it "applies size classes correctly" do
      result = helper.team_avatar(team1, size: :lg)
      expect(result).to include("h-10 w-10") # large size classes
    end

    it "applies custom classes" do
      result = helper.team_avatar(team1, css_class: "custom-class")
      expect(result).to include("custom-class")
    end

    it "returns fallback for nil team" do
      result = helper.team_avatar(nil)
      expect(result).to include("T") # default initial
    end
  end

  describe "#current_user_role_in_team" do
    before { helper.__current_user = user }

    it "returns user's role in specified team" do
      expect(helper.current_user_role_in_team(team1)).to eq("owner")
      expect(helper.current_user_role_in_team(team2)).to eq("member")
    end

    it "returns user's role in current team when no team specified" do
      helper.__current_team = team1
      expect(helper.current_user_role_in_team).to eq("owner")
    end

    it "returns nil when user has no access to team" do
      other_team = create(:team, name: "Other")
      expect(helper.current_user_role_in_team(other_team)).to be_nil
    end

    it "returns nil when no current user" do
      helper.__current_user = nil
      expect(helper.current_user_role_in_team(team1)).to be_nil
    end
  end

  describe "#can_manage_team?" do
    before { helper.__current_user = user }

    it "returns true for owner role" do
      expect(helper.can_manage_team?(team1)).to be true
    end

    it "returns true for admin role" do
      create(:membership, user: user, team: create(:team), role: :admin)
      admin_team = user.teams.joins(:memberships).where(memberships: { role: :admin }).first
      expect(helper.can_manage_team?(admin_team)).to be true
    end

    it "returns false for member role" do
      expect(helper.can_manage_team?(team2)).to be false
    end

    it "returns false when no current user" do
      helper.__current_user = nil
      expect(helper.can_manage_team?(team1)).to be false
    end

    it "uses current team when no team specified" do
      helper.__current_team = team1
      expect(helper.can_manage_team?).to be true
    end
  end

  describe "#team_scoped_path" do
    before { helper.__current_team = team1 }

    it "generates team-scoped paths with leading slash" do
      expect(helper.team_scoped_path("/dashboard")).to eq("/teams/#{team1.id}/dashboard")
    end

    it "handles paths without leading slash" do
      expect(helper.team_scoped_path("settings")).to eq("/teams/#{team1.id}/settings")
    end

    it "returns original path when no current team" do
      helper.__current_team = nil
      expect(helper.team_scoped_path("/dashboard")).to eq("/dashboard")
    end

    it "works with specified team parameter" do
      expect(helper.team_scoped_path("/projects", team2)).to eq("/teams/#{team2.id}/projects")
    end
  end

  describe "#team_switcher_data_attributes" do
    before do
      helper.__current_user = user
      helper.__current_team = team1
    end

    it "returns data attributes for Stimulus controller" do
      result = helper.team_switcher_data_attributes

      expect(result["controller"]).to eq("teams--team-switcher")
      expect(result["teams--team-switcher-current-team-value"]).to eq(team1.id.to_s)
      expect(result["teams--team-switcher-switch-url-value"]).to eq("/teams/switch/:team_id")
    end

    it "handles nil current team gracefully" do
      helper.__current_team = nil
      result = helper.team_switcher_data_attributes

      expect(result["controller"]).to eq("teams--team-switcher")
      expect(result["teams--team-switcher-current-team-value"]).to be_nil
    end
  end
end
