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
            timezone: "Eastern Time (US & Canada)",
            language: "en",
            email_notifications: {
              profile_updates: true,
              security_alerts: false,
              feature_announcements: true
            }
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
          expect(user.errors.full_messages.any? { |msg| msg.include?("invalid") }).to be true
        end
      end
    end
  end

  describe "timezone preferences" do
    before do
      # Mock TimezoneService for consistent testing
      allow(TimezoneService).to receive(:valid_timezone?) do |identifier|
        %w[UTC Eastern\ Time\ (US\ &\ Canada) Pacific\ Time\ (US\ &\ Canada) Central\ Time\ (US\ &\ Canada) Invalid/Timezone].include?(identifier) &&
        identifier != "Invalid/Timezone"
      end
    end

    describe "PATCH #update with timezone preference" do
      context "with valid timezone" do
        let(:params_with_timezone) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { timezone: "Eastern Time (US & Canada)" }
            }
          }
        end

        it "updates the user's timezone preference" do
          patch :update, params: params_with_timezone
          user.reload
          expect(user.timezone).to eq("Eastern Time (US & Canada)")
        end

        it "persists timezone in preferences model" do
          patch :update, params: params_with_timezone
          user.reload
          expect(user.preferences.timezone).to eq("Eastern Time (US & Canada)")
        end

        it "redirects successfully" do
          patch :update, params: params_with_timezone
          expect(response).to redirect_to(profile_path)
        end

        it "preserves other preferences" do
          user.preferences.language = "es"
          user.preferences.email_notifications.profile_updates = false
          user.save!

          patch :update, params: params_with_timezone
          user.reload

          expect(user.preferences.language).to eq("es")
          expect(user.preferences.email_notifications.profile_updates).to be false
          expect(user.preferences.timezone).to eq("Eastern Time (US & Canada)")
        end
      end

      context "with invalid timezone" do
        let(:params_with_invalid_timezone) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { timezone: "Invalid/Timezone" }
            }
          }
        end

        it "does not update the user's timezone preference" do
          original_timezone = user.timezone
          patch :update, params: params_with_invalid_timezone
          user.reload
          expect(user.timezone).to eq(original_timezone)
        end

        it "renders the edit page with validation errors" do
          patch :update, params: params_with_invalid_timezone
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "shows validation error for invalid timezone" do
          patch :update, params: params_with_invalid_timezone
          user.reload
          expect(user.errors.full_messages.any? { |msg| msg.include?("invalid") }).to be true
        end
      end

      context "with empty timezone" do
        let(:params_with_empty_timezone) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { timezone: "" }
            }
          }
        end

        it "defaults to UTC timezone" do
          patch :update, params: params_with_empty_timezone
          user.reload
          expect(user.timezone).to eq("UTC")
        end

        it "updates successfully" do
          patch :update, params: params_with_empty_timezone
          expect(response).to redirect_to(profile_path)
        end
      end

      context "when timezone parameter is missing" do
        let(:params_without_timezone) do
          {
            user: {
              display_name: "Updated Name",
              preferences: { language: "en" }
            }
          }
        end

        it "preserves existing timezone preference" do
          user.preferences.timezone = "Pacific Time (US & Canada)"
          user.save!
          patch :update, params: params_without_timezone
          user.reload
          expect(user.timezone).to eq("Pacific Time (US & Canada)")
        end
      end
    end

    describe "timezone options availability" do
      before do
        allow(TimezoneService).to receive(:timezone_options).and_return([
          [ "UTC", "UTC" ],
          [ "Eastern Time (US & Canada)", "Eastern Time (US & Canada)" ],
          [ "Pacific Time (US & Canada)", "Pacific Time (US & Canada)" ]
        ])
      end

      describe "GET #edit" do
        it "makes timezone options available through the view" do
          get :edit
          # The view should have access to TimezoneService.timezone_options
          # This will be tested in the view component specs
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "avatar upload functionality" do
    let(:valid_avatar) { fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg") }
    let(:invalid_avatar) { fixture_file_upload("spec/fixtures/files/document.pdf", "application/pdf") }

    describe "PATCH #update with avatar upload" do
      context "with valid avatar file" do
        let(:params_with_avatar) do
          {
            user: {
              display_name: "Updated Name",
              avatar: valid_avatar
            }
          }
        end

        it "attaches the avatar to the user" do
          patch :update, params: params_with_avatar
          user.reload
          expect(user.avatar).to be_attached
        end

        it "updates other profile fields" do
          patch :update, params: params_with_avatar
          user.reload
          expect(user.display_name).to eq("Updated Name")
        end

        it "redirects to profile page" do
          patch :update, params: params_with_avatar
          expect(response).to redirect_to(profile_path)
        end

        it "sets success flash message" do
          patch :update, params: params_with_avatar
          expect(flash[:notice]).to eq("Profile updated successfully!")
        end
      end

      context "with invalid avatar file" do
        let(:params_with_invalid_avatar) do
          {
            user: {
              display_name: "Updated Name",
              avatar: invalid_avatar
            }
          }
        end

        it "does not attach the invalid avatar" do
          patch :update, params: params_with_invalid_avatar
          user.reload
          expect(user.avatar).not_to be_attached
        end

        it "renders edit page with errors" do
          patch :update, params: params_with_invalid_avatar
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "shows avatar validation error" do
          patch :update, params: params_with_invalid_avatar
          user.reload
          expect(user.errors[:avatar]).to include("must be a JPEG, PNG, or WebP image")
        end
      end

      context "when removing avatar" do
        before do
          user.avatar.attach(valid_avatar)
          user.save!
        end

        let(:params_remove_avatar) do
          {
            user: {
              display_name: "Updated Name",
              remove_avatar: "1"
            }
          }
        end

        it "removes the attached avatar" do
          expect(user.avatar).to be_attached
          patch :update, params: params_remove_avatar
          user.reload
          expect(user.avatar).not_to be_attached
        end

        it "redirects successfully" do
          patch :update, params: params_remove_avatar
          expect(response).to redirect_to(profile_path)
        end
      end

      context "when replacing existing avatar" do
        let(:new_avatar) { fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg") }

        before do
          user.avatar.attach(valid_avatar)
          user.save!
        end

        let(:params_replace_avatar) do
          {
            user: {
              display_name: "Updated Name",
              avatar: new_avatar
            }
          }
        end

        it "replaces the existing avatar" do
          old_avatar_id = user.avatar.id
          patch :update, params: params_replace_avatar
          user.reload
          expect(user.avatar).to be_attached
          expect(user.avatar.id).not_to eq(old_avatar_id)
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
