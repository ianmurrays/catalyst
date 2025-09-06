require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  let(:user) { create(:user) }

  before do
    # Mock the authentication provider integration
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => "test@example.com"
    })
  end

  describe "GET #show" do
    it "renders the profile show page" do
      get :show
      expect(response).to have_http_status(:ok)
    end

    it "assigns the current user" do
      get :show
      expect(assigns(:user)).to eq(user)
    end
  end

  describe "GET #edit" do
    it "renders the profile edit page" do
      get :edit
      expect(response).to have_http_status(:ok)
    end

    it "assigns the current user" do
      get :edit
      expect(assigns(:user)).to eq(user)
    end
  end

  describe "PATCH #update" do
    let(:valid_params) do
      {
        user: {
          display_name: "Updated Name",
          bio: "Updated bio",
          phone: "+1234567890",
          preferences: {
            theme: "dark",
            timezone: "America/New_York",
            language: "en"
          }
        }
      }
    end

    context "with valid parameters" do
      it "updates the user" do
        patch :update, params: valid_params
        user.reload
        expect(user.display_name).to eq("Updated Name")
        expect(user.bio).to eq("Updated bio")
        expect(user.phone).to eq("+1234567890")
      end

      it "redirects to profile page" do
        patch :update, params: valid_params
        expect(response).to redirect_to(profile_path)
      end

      it "sets a success flash message" do
        patch :update, params: valid_params
        expect(flash[:notice]).to eq("Profile updated successfully!")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            display_name: "X", # Too short
            phone: "invalid-phone"
          }
        }
      end

      it "does not update the user" do
        original_name = user.display_name
        patch :update, params: invalid_params
        user.reload
        expect(user.display_name).to eq(original_name)
      end

      it "renders the edit page with errors" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "authentication requirements" do
    before do
      allow(controller).to receive(:logged_in?).and_return(false)
    end

    it "redirects to authentication provider when not logged in" do
      get :show
      expect(response).to redirect_to("/auth/auth0")
    end
  end
end
