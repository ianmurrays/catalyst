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
end
