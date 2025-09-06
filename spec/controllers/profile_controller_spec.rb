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
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when attempting to update email" do
      let(:params_with_email) do
        {
          user: {
            display_name: "Updated Name",
            email: "newemail@example.com"
          }
        }
      end

      it "does not allow email updates" do
        original_email = user.email
        patch :update, params: params_with_email
        user.reload
        expect(user.email).to eq(original_email)
      end

      it "still updates allowed fields" do
        patch :update, params: params_with_email
        user.reload
        expect(user.display_name).to eq("Updated Name")
      end
    end
  end

  describe "dynamic language options" do
    before do
      allow(LocaleService).to receive(:language_options).and_return([
        [ "English", "en" ],
        [ "Español (Spanish)", "es" ],
        [ "Dansk (Danish)", "da" ]
      ])
    end

    describe "GET #edit" do
      it "provides dynamic language options from LocaleService" do
        get :edit
        expect(LocaleService).to have_received(:language_options)
      end

      it "makes language options available to the view" do
        get :edit
        expect(assigns(:user).available_languages).to eq([
          [ "English", "en" ],
          [ "Español (Spanish)", "es" ],
          [ "Dansk (Danish)", "da" ]
        ])
      end
    end

    describe "PATCH #update with language preference" do
      context "with valid language code" do
        let(:params_with_language) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { language: "es" }
            }
          }
        end

        before do
          allow(LocaleService).to receive(:available_locales).and_return([ :en, :es, :da ])
        end

        it "updates the user's language preference" do
          patch :update, params: params_with_language
          user.reload
          expect(user.language).to eq("es")
        end

        it "redirects successfully" do
          patch :update, params: params_with_language
          expect(response).to redirect_to(profile_path)
        end
      end

      context "with invalid language code" do
        let(:params_with_invalid_language) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { language: "fr" }
            }
          }
        end

        before do
          allow(LocaleService).to receive(:available_locales).and_return([ :en, :es, :da ])
        end

        it "does not update the user's language preference" do
          original_language = user.language
          patch :update, params: params_with_invalid_language
          user.reload
          expect(user.language).to eq(original_language)
        end

        it "renders the edit page with validation errors" do
          patch :update, params: params_with_invalid_language
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "shows validation error for invalid language" do
          patch :update, params: params_with_invalid_language
          user.reload
          expect(user.errors[:language]).to include("is not available")
        end
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
