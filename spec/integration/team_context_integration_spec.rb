# frozen_string_literal: true

require "rails_helper"

# Simplified integration tests focusing on essential team context functionality
RSpec.describe "Team Context Integration", type: :request do
  let(:user) { create(:user, display_name: "John Doe") }
  let(:team1) { create(:team, name: "Team Alpha") }
  let(:team2) { create(:team, name: "Team Beta") }

  before do
    # Create user memberships
    create(:membership, user: user, team: team1, role: :owner)
    create(:membership, user: user, team: team2, role: :member)

    # Mock authentication in session (simpler approach for request specs)
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "Basic team switching functionality" do
    it "successfully switches teams via POST request" do
      post "/teams/switch/#{team1.id}"

      expect(response).to be_redirect
      follow_redirect!
      expect(response).to be_successful
    end

    it "handles team switching with return_to parameter" do
      post "/teams/switch/#{team1.id}", params: { return_to: "/teams" }

      expect(response).to redirect_to("/teams")
    end

    it "prevents unauthorized team switching" do
      unauthorized_team = create(:team, name: "Unauthorized Team")

      post "/teams/switch/#{unauthorized_team.id}"

      expect(response).to be_redirect
      expect(flash[:alert]).to be_present
    end

    it "handles non-existent team gracefully" do
      post "/teams/switch/99999"

      expect(response).to redirect_to("/teams")
      expect(flash[:alert]).to be_present
    end
  end

  describe "JSON API integration" do
    it "returns proper JSON response for successful team switching" do
      post "/teams/switch/#{team1.id}",
           headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response['status']).to eq('success')
      expect(json_response['team']['id']).to eq(team1.id)
      expect(json_response['team']['name']).to eq(team1.name)
      expect(json_response['team']['role']).to eq('owner')
    end

    it "returns proper error JSON for unauthorized access" do
      unauthorized_team = create(:team, name: "Unauthorized Team")

      post "/teams/switch/#{unauthorized_team.id}",
           headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:forbidden)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to be_present
    end

    it "returns JSON error for non-existent team" do
      post "/teams/switch/99999",
           headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to be_present
    end
  end

  describe "Security validation in integration" do
    it "requires user authentication for team switching" do
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(false)

      post "/teams/switch/#{team1.id}"

      # Should redirect to auth (handled by Secured concern)
      expect(response).to be_redirect
    end

    it "validates team membership before switching" do
      # Create a team the user doesn't belong to
      other_user = create(:user)
      other_team = create(:team)
      create(:membership, user: other_user, team: other_team, role: :owner)

      post "/teams/switch/#{other_team.id}"

      expect(response).to be_redirect
      expect(flash[:alert]).to be_present
    end
  end

  describe "Application integration" do
    it "allows access to team-related pages after authentication" do
      get "/teams"

      expect(response).to be_successful
    end

    it "team switching integrates with navbar/UI components" do
      # Test that team switching works in the context of UI components
      post "/teams/switch/#{team1.id}"

      get "/teams"
      expect(response).to be_successful

      # Basic check that the page renders (integration with components)
      expect(response.body).to be_present
    end
  end

  describe "Error handling in integration context" do
    it "handles database errors during team switch" do
      # Simulate database error - this should raise and be handled by Rails error pages
      allow(Team).to receive(:find).and_raise(ActiveRecord::ConnectionNotEstablished)

      expect {
        post "/teams/switch/#{team1.id}"
      }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      # This test verifies the error is properly raised rather than silently failing
    end

    it "maintains application stability with malformed requests" do
      # Test that malformed parameters don't break the app
      expect {
        post "/teams/switch/", params: { malformed: "data" }
      }.not_to raise_error
    end
  end
end
