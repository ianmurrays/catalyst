require 'rails_helper'

RSpec.describe OnboardingController, type: :controller do
  let(:user) { create(:user) }
  let(:user_with_team) { create(:user) }
  let(:team) { create(:team) }

  before do
    # Mock the authentication provider integration
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })

    # Create membership for user_with_team
    create(:membership, user: user_with_team, team: team, role: :owner)
  end

  describe "GET #show" do
    context "when user has no teams" do
      it "renders the onboarding page" do
        get :show
        expect(response).to have_http_status(:ok)
      end

      it "assigns can_create_teams based on configuration" do
        allow(Rails.configuration).to receive(:allow_team_creation).and_return(true)
        get :show
        expect(assigns(:can_create_teams)).to be true
      end

      context "when team creation is disabled" do
        before do
          allow(Rails.configuration).to receive(:allow_team_creation).and_return(false)
        end

        it "assigns can_create_teams as false" do
          get :show
          expect(assigns(:can_create_teams)).to be false
        end
      end
    end

    context "when user has teams" do
      before do
        allow(controller).to receive(:current_user).and_return(user_with_team)
        allow(controller).to receive(:current_auth_provider_user).and_return({
          "sub" => user_with_team.auth0_sub,
          "name" => user_with_team.display_name,
          "email" => user_with_team.email
        })
      end

      it "redirects to teams path" do
        get :show
        expect(response).to redirect_to(teams_path)
      end

      it "does not render the onboarding page" do
        get :show
        expect(response).not_to have_http_status(:ok)
      end
    end
  end

  describe "POST #create_team" do
    let(:valid_team_params) do
      {
        team: {
          name: "My First Team"
        }
      }
    end

    let(:invalid_team_params) do
      {
        team: {
          name: ""
        }
      }
    end

    context "when team creation is allowed" do
      before do
        allow(Rails.configuration).to receive(:allow_team_creation).and_return(true)
      end

      context "with valid parameters" do
        it "creates a new team" do
          expect {
            post :create_team, params: valid_team_params
          }.to change(Team, :count).by(1)
        end

        it "makes the current user the owner" do
          post :create_team, params: valid_team_params
          team = Team.last
          expect(team.owner?(user)).to be true
        end

        it "redirects to the team path" do
          post :create_team, params: valid_team_params
          team = Team.last
          expect(response).to redirect_to(team_path(team))
        end

        it "sets a success flash message" do
          post :create_team, params: valid_team_params
          expect(flash[:notice]).to eq(I18n.t("onboarding.flash.team_created"))
        end
      end

      context "with invalid parameters" do
        it "does not create a team" do
          expect {
            post :create_team, params: invalid_team_params
          }.not_to change(Team, :count)
        end

        it "renders the show template with errors" do
          post :create_team, params: invalid_team_params
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "assigns the team with errors" do
          post :create_team, params: invalid_team_params
          expect(assigns(:team)).to be_present
          expect(assigns(:team).errors).to be_present
        end
      end
    end

    context "when team creation is disabled" do
      before do
        allow(Rails.configuration).to receive(:allow_team_creation).and_return(false)
      end

      it "redirects to onboarding path with alert" do
        post :create_team, params: valid_team_params
        expect(response).to redirect_to(onboarding_path)
        expect(flash[:alert]).to eq(I18n.t("onboarding.team_creation_disabled"))
      end

      it "does not create a team" do
        expect {
          post :create_team, params: valid_team_params
        }.not_to change(Team, :count)
      end
    end
  end

  describe "authentication requirements" do
    before do
      allow(controller).to receive(:logged_in?).and_return(false)
    end

    it "redirects to authentication when not logged in" do
      get :show
      expect(response).to redirect_to(login_path)
    end

    it "stores return path in session" do
      get :show
      expect(session[:return_to]).to eq(onboarding_path)
    end
  end

  describe "team requirement exemption" do
    it "does not require a team to be set" do
      # This test ensures that skip_before_action :require_team is working
      # By default, most controllers require a team context, but onboarding should not
      expect(controller).not_to receive(:set_current_team)
      get :show
    end
  end

  describe "strong parameters" do
    let(:params_with_extra_fields) do
      {
        team: {
          name: "Valid Team",
          slug: "hacker-slug",
          deleted_at: Time.current,
          id: 999
        }
      }
    end

    before do
      allow(Rails.configuration).to receive(:allow_team_creation).and_return(true)
    end

    it "only permits allowed parameters" do
      post :create_team, params: params_with_extra_fields
      team = Team.last
      expect(team.name).to eq("Valid Team")
      expect(team.slug).not_to eq("hacker-slug") # Should be auto-generated
      expect(team.deleted_at).to be_nil
    end
  end
end