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
    end

    it "falls back to cookies.encrypted[:last_team_id] when session missing" do
      session.delete(:current_team_id)
      cookies.encrypted[:last_team_id] = team1.id

      get :index

      expect(response.body).to eq(team1.id.to_s)
      expect(session[:current_team_id]).to eq(team1.id)
    end

    it "defaults to the first available team when no session or cookie" do
      session.delete(:current_team_id)
      cookies.delete(:last_team_id)

      get :index

      # current_user.teams.first could be either, depending on creation order; ensure it's one of them
      selected_team_id = response.body.to_i
      expect([ team1.id, team2.id ]).to include(selected_team_id)
      expect(session[:current_team_id]).to eq(selected_team_id)
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
  end
end
