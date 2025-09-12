# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Team Creation Configuration", type: :request do
  let(:user) { create(:user) }

  # Stub authentication for request specs to avoid OmniAuth CSRF requirements
  before do
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /teams/new" do
    context "when team creation is enabled" do
      it "allows access to team creation page" do
        with_team_creation_allowed(true) do
          get new_team_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Create New Team")
        end
      end
    end

    context "when team creation is disabled" do
      it "redirects to teams index with error message" do
        with_team_creation_allowed(false) do
          get new_team_path
          
          expect(response).to redirect_to(teams_path)
          follow_redirect!
          
          expect(response.body).to include(I18n.t("teams.flash.creation_disabled"))
        end
      end
    end
  end

  describe "POST /teams" do
    let(:team_params) { { team: { name: "Test Team" } } }

    context "when team creation is enabled" do
      it "creates a new team successfully" do
        with_team_creation_allowed(true) do
          expect {
            post teams_path, params: team_params
          }.to change(Team, :count).by(1)

          expect(response).to redirect_to(team_path(Team.last))
          follow_redirect!

          expect(response.body).to include("Test Team")
        end
      end
    end

    context "when team creation is disabled" do
      it "prevents team creation" do
        with_team_creation_allowed(false) do
          expect {
            post teams_path, params: team_params
          }.not_to change(Team, :count)

          expect(response).to redirect_to(teams_path)
          follow_redirect!

          expect(response.body).to include(I18n.t("teams.flash.creation_disabled"))
        end
      end
    end
  end

  describe "configuration state persistence" do
    it "maintains configuration across requests" do
      with_team_creation_allowed(false) do
        get new_team_path
        expect(response).to redirect_to(teams_path)
        
        get new_team_path
        expect(response).to redirect_to(teams_path)
      end
    end
  end

  describe "helper method integration" do
    let(:teams_controller) { TeamsController.new }
    
    before do
      teams_controller.instance_variable_set(:@current_user, user)
    end

    it "can_create_teams? helper reflects configuration" do
      with_team_creation_allowed(true) do
        expect(teams_controller.helpers.can_create_teams?).to be true
      end

      with_team_creation_allowed(false) do
        expect(teams_controller.helpers.can_create_teams?).to be false
      end
    end
  end
end
