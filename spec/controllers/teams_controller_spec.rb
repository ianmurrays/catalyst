require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team) }
  let(:user_team) { create(:team) }

  before do
    # Mock the authentication provider integration
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })

    # Create membership for user_team
    create(:membership, user: user, team: user_team, role: :owner)
  end

  describe "GET #index" do
    it "renders the teams index page" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "assigns the user's teams" do
      get :index
      expect(assigns(:teams)).to include(user_team)
      expect(assigns(:teams)).not_to include(team)
    end
  end

  describe "GET #show" do
    context "when user is a member of the team" do
      it "renders the team show page" do
        get :show, params: { id: user_team.slug }
        expect(response).to have_http_status(:ok)
      end

      it "assigns the team" do
        get :show, params: { id: user_team.slug }
        expect(assigns(:team)).to eq(user_team)
      end
    end

    context "when user is not a member of the team" do
      it "redirects to root with authorization error" do
        get :show, params: { id: team.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end

    context "when team is deleted" do
      before { user_team.destroy }

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          get :show, params: { id: user_team.slug }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "GET #new" do
    it "renders the new team page" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "assigns a new team" do
      get :new
      expect(assigns(:team)).to be_a_new(Team)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        team: {
          name: "New Team"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new team" do
        expect {
          post :create, params: valid_params
        }.to change(Team, :count).by(1)
      end

      it "creates the user as owner" do
        post :create, params: valid_params
        team = Team.last
        expect(team.owner?(user)).to be true
      end

      it "redirects to the team show page" do
        post :create, params: valid_params
        team = Team.last
        expect(response).to redirect_to(team_path(team))
      end

      it "sets a success flash message" do
        post :create, params: valid_params
        expect(flash[:notice]).to eq(I18n.t("teams.flash.created"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          team: {
            name: "" # Invalid: blank name
          }
        }
      end

      it "does not create a team" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Team, :count)
      end

      it "renders the new template with errors" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "assigns the team with errors" do
        post :create, params: invalid_params
        expect(assigns(:team).errors[:name]).not_to be_empty
      end
    end
  end

  describe "GET #edit" do
    context "when user is admin/owner of the team" do
      it "renders the edit team page" do
        get :edit, params: { id: user_team.slug }
        expect(response).to have_http_status(:ok)
      end

      it "assigns the team" do
        get :edit, params: { id: user_team.slug }
        expect(assigns(:team)).to eq(user_team)
      end
    end

    context "when user is not admin/owner of the team" do
      let(:member_team) { create(:team) }

      before do
        create(:membership, user: user, team: member_team, role: :member)
      end

      it "redirects to root with authorization error" do
        get :edit, params: { id: member_team.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_params) do
      {
        id: user_team.slug,
        team: {
          name: "Updated Team Name"
        }
      }
    end

    context "with valid parameters" do
      it "updates the team" do
        patch :update, params: valid_params
        user_team.reload
        expect(user_team.name).to eq("Updated Team Name")
      end

      it "redirects to the team show page" do
        patch :update, params: valid_params
        expect(response).to redirect_to(team_path(user_team))
      end

      it "sets a success flash message" do
        patch :update, params: valid_params
        expect(flash[:notice]).to eq(I18n.t("teams.flash.updated"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          id: user_team.slug,
          team: {
            name: "" # Invalid: blank name
          }
        }
      end

      it "does not update the team" do
        original_name = user_team.name
        patch :update, params: invalid_params
        user_team.reload
        expect(user_team.name).to eq(original_name)
      end

      it "renders the edit template with errors" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is not admin/owner" do
      let(:member_team) { create(:team) }

      before do
        create(:membership, user: user, team: member_team, role: :member)
      end

      it "redirects to root with authorization error" do
        patch :update, params: { id: member_team.slug, team: { name: "New Name" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user is owner of the team" do
      it "soft deletes the team" do
        expect {
          delete :destroy, params: { id: user_team.slug }
        }.to change { user_team.reload.deleted? }.from(false).to(true)
      end

      it "redirects to teams index" do
        delete :destroy, params: { id: user_team.slug }
        expect(response).to redirect_to(teams_path)
      end

      it "sets a success flash message" do
        delete :destroy, params: { id: user_team.slug }
        expect(flash[:notice]).to eq(I18n.t("teams.flash.deleted"))
      end
    end

    context "when user is admin but not owner" do
      let(:admin_team) { create(:team) }

      before do
        create(:membership, user: other_user, team: admin_team, role: :owner)
        create(:membership, user: user, team: admin_team, role: :admin)
      end

      it "redirects to root with authorization error" do
        delete :destroy, params: { id: admin_team.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end

  describe "PATCH #restore" do
    let(:deleted_team) { create(:team) }

    before do
      create(:membership, user: user, team: deleted_team, role: :owner)
      deleted_team.destroy
    end

    context "when user is owner of the deleted team" do
      it "restores the team" do
        expect {
          patch :restore, params: { id: deleted_team.slug }
        }.to change { deleted_team.reload.deleted? }.from(true).to(false)
      end

      it "redirects to the team show page" do
        patch :restore, params: { id: deleted_team.slug }
        expect(response).to redirect_to(team_path(deleted_team))
      end

      it "sets a success flash message" do
        patch :restore, params: { id: deleted_team.slug }
        expect(flash[:notice]).to eq(I18n.t("teams.flash.restored"))
      end
    end
  end

  describe "authentication requirements" do
    before do
      allow(controller).to receive(:logged_in?).and_return(false)
    end

    it "redirects to authentication provider when not logged in" do
      get :index
      expect(response).to redirect_to("/auth/auth0")
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

    it "only permits allowed parameters" do
      post :create, params: params_with_extra_fields
      team = Team.last
      expect(team.name).to eq("Valid Team")
      expect(team.slug).not_to eq("hacker-slug") # Should be auto-generated
      expect(team.deleted_at).to be_nil
    end
  end
end
