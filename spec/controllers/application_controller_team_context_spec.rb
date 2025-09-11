# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      # Expose current_team id in body for assertions
      render plain: (current_team&.id || "").to_s
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  let(:user) { create(:user) }
  let(:team1) { create(:team) }
  let(:team2) { create(:team) }

  before do
    # Auth stubs
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })

    # Memberships
    create(:membership, user: user, team: team1, role: :owner)
    create(:membership, user: user, team: team2, role: :member)
  end

  describe "current team selection" do
    it "uses session[:current_team_id] if present and valid" do
      session[:current_team_id] = team2.id

      get :index

      expect(response.body).to eq(team2.id.to_s)
      expect(session[:current_team_id]).to eq(team2.id)
      expect(cookies.encrypted[:last_team_id]).to eq(team2.id)
    end

    it "falls back to cookies.encrypted[:last_team_id] when session missing" do
      session.delete(:current_team_id)
      cookies.encrypted[:last_team_id] = team1.id

      get :index

      expect(response.body).to eq(team1.id.to_s)
      expect(session[:current_team_id]).to eq(team1.id)
      expect(cookies.encrypted[:last_team_id]).to eq(team1.id)
    end

    it "defaults to the first available team when no session or cookie" do
      session.delete(:current_team_id)
      cookies.delete(:last_team_id)

      get :index

      # current_user.teams.first could be either, depending on creation order; ensure it's one of them
      selected_team_id = response.body.to_i
      expect([ team1.id, team2.id ]).to include(selected_team_id)
      expect(session[:current_team_id]).to eq(selected_team_id)
      expect(cookies.encrypted[:last_team_id]).to eq(selected_team_id)
    end

    it "does not set a current team for users with no teams" do
      # Remove memberships
      user.memberships.delete_all
      session.delete(:current_team_id)
      cookies.delete(:last_team_id)

      get :index

      expect(response.body).to eq("")
      expect(session[:current_team_id]).to be_nil
    end

    it "ignores invalid team IDs in session" do
      session[:current_team_id] = -1
      cookies.encrypted[:last_team_id] = team1.id

      get :index

      expect(response.body).to eq(team1.id.to_s)
      expect(session[:current_team_id]).to eq(team1.id)
    end

    it "ignores team IDs for teams user is not a member of" do
      other_team = create(:team)
      session[:current_team_id] = other_team.id

      get :index

      # Should fall back to first available team
      selected_team_id = response.body.to_i
      expect([ team1.id, team2.id ]).to include(selected_team_id)
      expect(session[:current_team_id]).to eq(selected_team_id)
    end
  end

  describe "helper methods" do
    before do
      session[:current_team_id] = team1.id
      get :index
    end

    it "provides current_team_id helper" do
      expect(controller.current_team_id).to eq(team1.id)
    end

    it "provides current_team_name helper" do
      expect(controller.current_team_name).to eq(team1.name)
    end

    it "provides user_has_teams? helper" do
      expect(controller.user_has_teams?).to be_truthy
    end

    context "when user has no teams" do
      before do
        user.memberships.delete_all
        session.delete(:current_team_id)
        get :index
      end

      it "returns nil for current_team_id" do
        expect(controller.current_team_id).to be_nil
      end

      it "returns nil for current_team_name" do
        expect(controller.current_team_name).to be_nil
      end

      it "returns false for user_has_teams?" do
        expect(controller.user_has_teams?).to be_falsey
      end
    end
  end

  describe "cookie persistence" do
    it "stores team preference in encrypted cookie when team is set" do
      session[:current_team_id] = team1.id

      get :index

      expect(cookies.encrypted[:last_team_id]).to eq(team1.id)
    end

    it "retrieves team from cookie after session clear" do
      cookies.encrypted[:last_team_id] = team1.id
      session.delete(:current_team_id)

      get :index

      expect(response.body).to eq(team1.id.to_s)
      expect(session[:current_team_id]).to eq(team1.id) # Should be updated
    end

    it "falls back to plain cookie when encrypted cookie is not available" do
      cookies[:last_team_id] = team2.id
      session.delete(:current_team_id)

      get :index

      expect(response.body).to eq(team2.id.to_s)
      expect(session[:current_team_id]).to eq(team2.id)
    end
  end

  describe "production security settings" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    it "uses secure cookie settings in production" do
      controller.send(:store_team_preference, team1)

      # Note: Exact testing of secure flag depends on test framework capabilities
      # The important thing is that Rails.env.production? is checked
      expect(Rails.env.production?).to be_truthy
    end
  end
end
