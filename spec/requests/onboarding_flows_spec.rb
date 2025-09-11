require 'rails_helper'

RSpec.describe "Onboarding Flows", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:existing_user_with_team) { create(:user) }
  let(:invitation_token) { "raw_invitation_token_123" }

  before do
    create(:membership, user: existing_user_with_team, team: team, role: :owner)
  end

  # Helper method to simulate login without going through OmniAuth
  def login_as_user(user)
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })
  end

  describe "Flow 1: New User Without Invitation" do
    context "when team creation is allowed" do
      before do
        allow(Rails.configuration).to receive(:allow_team_creation).and_return(true)
      end

      it "redirects new user to onboarding and allows team creation" do
        # Login as user without teams
        login_as_user(user)
        
        # Visit onboarding page directly (simulating redirect from auth)
        get onboarding_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to")
        expect(response.body).to include("Create Your First Team")
      end

      it "allows team creation from onboarding page" do
        # Login as user without teams
        login_as_user(user)

        # Create team from onboarding
        expect {
          post "/onboarding/create_team", params: {
            team: { name: "My First Team" }
          }
        }.to change(Team, :count).by(1)

        new_team = Team.last
        expect(new_team.name).to eq("My First Team")
        expect(new_team.owner?(user)).to be true
        expect(response).to redirect_to(team_path(new_team))
      end
    end

    context "when team creation is disabled" do
      before do
        allow(Rails.configuration).to receive(:allow_team_creation).and_return(false)
      end

      it "shows waiting for invitation message" do
        simulate_auth_callback({
          "email" => user.email,
          "name" => user.display_name,
          "sub" => user.auth0_sub
        })

        follow_redirect! # Follow redirect to onboarding

        expect(response.body).to include("Waiting for Invitation")
        expect(response.body).to include("You need to be invited to a team")
      end

      it "prevents team creation" do
        # Login as user
        simulate_auth_callback({
          "email" => user.email,
          "name" => user.display_name,
          "sub" => user.auth0_sub
        })

        # Try to create team (should be blocked)
        expect {
          post "/onboarding/create_team", params: {
            team: { name: "Blocked Team" }
          }
        }.not_to change(Team, :count)

        expect(response).to redirect_to(onboarding_path)
        expect(flash[:alert]).to include("Team creation is currently disabled")
      end
    end
  end

  describe "Flow 2: New User With Invitation" do
    let(:invitation) { create(:invitation, team: team, role: :member) }
    let(:raw_token) { "raw_token_#{SecureRandom.hex(32)}" }

    before do
      # Mock the invitation service to return our test data
      allow(Teams::InvitationService).to receive(:digest).with(raw_token).and_return(invitation.token)
    end

    it "accepts invitation automatically after authentication" do
      # Step 1: User clicks invitation link (not logged in)
      get accept_invitation_path(token: raw_token)

      expect(response).to redirect_to(login_path)
      expect(session[:invitation_token]).to eq(raw_token)

      # Step 2: User authenticates via Auth0
      simulate_auth_callback({
        "email" => user.email,
        "name" => user.display_name,
        "sub" => user.auth0_sub
      })

      # Should redirect to invitation acceptance, not onboarding
      expect(response).to redirect_to(accept_invitation_path(token: raw_token))
      expect(session[:invitation_token]).to be_nil

      follow_redirect!

      # Step 3: Invitation should be accepted
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You've joined")
      expect(team.has_member?(User.find_by(auth0_sub: user.auth0_sub))).to be true
    end
  end

  describe "Flow 3: Existing User With Invitation" do
    let(:invitation) { create(:invitation, team: team, role: :member) }
    let(:raw_token) { "raw_token_#{SecureRandom.hex(32)}" }
    let(:existing_user) { create(:user) }

    before do
      allow(Teams::InvitationService).to receive(:digest).with(raw_token).and_return(invitation.token)
      
      # Login as existing user
      simulate_auth_callback({
        "email" => existing_user.email,
        "name" => existing_user.display_name,
        "sub" => existing_user.auth0_sub
      })
    end

    it "accepts invitation directly without Auth0 redirect" do
      # User is already authenticated, clicks invitation link
      get accept_invitation_path(token: raw_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You've joined")
      expect(team.has_member?(existing_user)).to be true
    end
  end

  describe "Flow 4: Existing User Without Teams" do
    let(:existing_user_no_teams) { create(:user) }

    it "redirects to onboarding when accessing app" do
      # Login user who has no teams
      simulate_auth_callback({
        "email" => existing_user_no_teams.email,
        "name" => existing_user_no_teams.display_name,
        "sub" => existing_user_no_teams.auth0_sub
      })

      expect(response).to redirect_to(onboarding_path)
    end
  end

  describe "Flow 5: User With Teams" do
    it "redirects to home, not onboarding" do
      # Login user who has teams
      simulate_auth_callback({
        "email" => existing_user_with_team.email,
        "name" => existing_user_with_team.display_name,
        "sub" => existing_user_with_team.auth0_sub
      })

      expect(response).to redirect_to("/")
      follow_redirect!
      expect(response).not_to redirect_to(onboarding_path)
    end
  end

  describe "Edge Cases" do
    context "user visits onboarding but has teams" do
      it "redirects to teams path" do
        # Login user with teams
        post "/auth/auth0/callback", env: {
          "omniauth.auth" => OmniAuth::AuthHash.new({
            "extra" => {
              "raw_info" => {
                "email" => existing_user_with_team.email,
                "name" => existing_user_with_team.display_name,
                "sub" => existing_user_with_team.auth0_sub
              }
            }
          })
        }

        # Try to access onboarding
        get onboarding_path
        expect(response).to redirect_to(teams_path)
      end
    end

    context "expired invitation" do
      let(:expired_invitation) { create(:invitation, team: team, role: :member, expires_at: 1.hour.ago) }
      let(:raw_token) { "expired_token_#{SecureRandom.hex(32)}" }

      before do
        allow(Teams::InvitationService).to receive(:digest).with(raw_token).and_return(expired_invitation.token)
      end

      it "shows error message and redirects to root" do
        # Login first
        simulate_auth_callback({
          "email" => user.email,
          "name" => user.display_name,
          "sub" => user.auth0_sub
        })

        # Try to accept expired invitation
        get accept_invitation_path(token: raw_token)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("expired")
      end
    end
  end
end