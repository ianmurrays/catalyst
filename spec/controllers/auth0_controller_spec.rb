require 'rails_helper'

RSpec.describe Auth0Controller, type: :controller do
  let(:valid_auth_info) do
    {
      "extra" => {
        "raw_info" => {
          "sub" => "auth0|123456789",
          "name" => "John Doe",
          "email" => "john@example.com"
        }
      }
    }
  end

  let(:auth_info_without_email) do
    {
      "extra" => {
        "raw_info" => {
          "sub" => "auth0|123456789",
          "name" => "John Doe"
        }
      }
    }
  end

  describe "#callback" do
    context "with valid authentication info including email" do
      before do
        request.env["omniauth.auth"] = valid_auth_info
      end

      it "creates or finds the user" do
        expect {
          post :callback
        }.to change(User, :count).by(1)
      end

      it "sets the userinfo in session" do
        post :callback
        expect(session[:userinfo]).to eq(valid_auth_info["extra"]["raw_info"])
      end

      it "has default redirect behavior tested in context-specific tests" do
        # This test is now covered by the context-specific tests below
        # The actual redirect depends on whether user has teams or not
        expect { post :callback }.not_to raise_error
      end

      context "with a return_to URL in session" do
        before { session[:return_to] = "/profile" }

        it "redirects to the return_to URL" do
          post :callback
          expect(response).to redirect_to("/profile")
        end

        it "clears the return_to from session" do
          post :callback
          expect(session[:return_to]).to be_nil
        end
      end

      context "when an invitation token is present in session" do
        it "redirects to the invitation acceptance path and clears the token" do
          session[:invitation_token] = "rawtoken123"
          post :callback
          expect(response).to redirect_to(accept_invitation_path(token: "rawtoken123"))
          expect(session[:invitation_token]).to be_nil
        end
      end

      context "when user has no teams (onboarding flow)" do
        let!(:user_without_teams) { create(:user, auth0_sub: "auth0|123456789") }

        it "redirects to onboarding page" do
          post :callback
          expect(response).to redirect_to(onboarding_path)
        end
      end

      context "when user has teams" do
        let!(:user_with_teams) { create(:user, auth0_sub: "auth0|123456789") }
        let!(:team) { create(:team) }
        
        before do
          create(:membership, user: user_with_teams, team: team, role: :owner)
        end

        it "redirects to root path" do
          post :callback
          expect(response).to redirect_to("/")
        end
      end

      context "when user already exists" do
        let!(:existing_user) { create(:user, auth0_sub: "auth0|123456789") }

        it "does not create a new user" do
          expect {
            post :callback
          }.not_to change(User, :count)
        end

        it "still sets session" do
          post :callback
          expect(session[:userinfo]).to eq(valid_auth_info["extra"]["raw_info"])
        end
      end
    end

    context "when email is missing from auth provider" do
      before do
        request.env["omniauth.auth"] = auth_info_without_email
      end

      it "does not create a user" do
        expect {
          post :callback
        }.not_to change(User, :count)
      end

      it "does not set userinfo in session" do
        post :callback
        expect(session[:userinfo]).to be_nil
      end

      it "renders the failure view" do
        post :callback
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns unprocessable_content status" do
        post :callback
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders with the correct error message" do
        expect(Views::Auth0::Failure).to receive(:new).with(error_msg: /Email is required from authentication provider/).and_call_original
        post :callback
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Authentication failed:/)
        post :callback
      end
    end

    context "when user creation fails for other reasons" do
      before do
        request.env["omniauth.auth"] = valid_auth_info
        allow(User).to receive(:find_or_create_from_auth_provider).and_raise(StandardError, "Database error")
      end

      it "renders the failure view" do
        post :callback
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Authentication error:/)
        post :callback
      end

      it "renders with generic error message" do
        expect(Views::Auth0::Failure).to receive(:new).with(error_msg: "Authentication failed. Please try again or contact support.").and_call_original
        post :callback
      end
    end
  end

  describe "#failure" do
    it "renders failure view with custom error message" do
      expect(Views::Auth0::Failure).to receive(:new).with(error_msg: "Custom error message").and_call_original
      get :failure, params: { message: "Custom error message" }
      expect(response).to have_http_status(:ok)
    end

    it "renders failure view with default error message when no message provided" do
      expect(Views::Auth0::Failure).to receive(:new).with(error_msg: "Authentication failed. Please try again or contact support.").and_call_original
      get :failure
      expect(response).to have_http_status(:ok)
    end

    it "logs the failure" do
      expect(Rails.logger).to receive(:error).with(/Authentication failure:/)
      get :failure, params: { message: "Test error" }
    end
  end

  describe "#logout" do
    let(:team) { create(:team) }

    before do
      session[:userinfo] = { "sub" => "auth0|123456789" }
      session[:current_team_id] = team.id
      cookies.encrypted[:last_team_id] = team.id
    end

    it "clears userinfo and current_team_id from session" do
      post :logout
      expect(session[:userinfo]).to be_nil
      expect(session[:current_team_id]).to be_nil
    end

    it "preserves team preference cookie for next login" do
      post :logout
      expect(cookies.encrypted[:last_team_id]).to eq(team.id)
    end

    it "redirects to Auth0 logout URL" do
      post :logout
      expect(response).to redirect_to(/auth0\.com\/v2\/logout/)
    end
  end
end
