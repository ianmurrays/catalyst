# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSwitchController, type: :controller do
  let(:user) { create(:user, display_name: "John Doe") }
  let(:team_a) { create(:team, name: "Team Alpha") }
  let(:team_b) { create(:team, name: "Team Beta") }
  let(:other_team) { create(:team, name: "Other Team") }

  before do
    # Memberships
    create(:membership, user: user, team: team_a, role: :owner)
    create(:membership, user: user, team: team_b, role: :member)
    # Not a member of other_team

    # Auth
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })
  end

  describe "POST #update" do
    context "with valid team" do
      it "switches current team, updates session and cookie, resets pundit context, and redirects back" do
        request.env["HTTP_REFERER"] = "/previous"

        expect(controller).to receive(:pundit_reset!).and_call_original
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("User #{user.id} switched to team #{team_b.id} (#{team_b.name})")

        post :update, params: { team_id: team_b.id }

        expect(session[:current_team_id]).to eq(team_b.id)
        expect(cookies.encrypted[:last_team_id]).to eq(team_b.id)
        expect(response).to redirect_to("/previous")
        expect(flash[:notice]).to eq(I18n.t("teams.notifications.switch_success", team_name: team_b.name))
      end

      it "uses consistent cookie settings via store_team_preference method" do
        post :update, params: { team_id: team_a.id }

        expect(cookies.encrypted[:last_team_id]).to eq(team_a.id)
      end

      it "logs the team switch for audit trail" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("User #{user.id} switched to team #{team_a.id} (#{team_a.name})")

        post :update, params: { team_id: team_a.id }
      end

      it "clears cached team data" do
        controller.instance_variable_set(:@current_team, team_a)

        post :update, params: { team_id: team_b.id }

        expect(controller.instance_variable_defined?(:@current_team)).to be false
      end
    end

    context "with redirect logic" do
      it "redirects to return_to parameter when provided and safe" do
        post :update, params: { team_id: team_a.id, return_to: "/dashboard" }

        expect(response).to redirect_to("/dashboard")
      end

      it "ignores unsafe redirect URLs" do
        post :update, params: { team_id: team_a.id, return_to: "https://evil.com" }

        expect(response).to redirect_to(teams_path)
      end

      it "redirects to same-site referrer when no return_to" do
        request.env["HTTP_REFERER"] = "http://test.host/some-page"

        post :update, params: { team_id: team_a.id }

        expect(response).to redirect_to("http://test.host/some-page")
      end

      it "ignores cross-site referrer" do
        request.env["HTTP_REFERER"] = "https://evil.com/page"

        post :update, params: { team_id: team_a.id }

        expect(response).to redirect_to(teams_path)
      end

      it "defaults to teams path when no referrer or return_to" do
        post :update, params: { team_id: team_a.id }

        expect(response).to redirect_to(teams_path)
      end
    end

    context "with unauthorized team" do
      it "redirects with error message for non-member" do
        post :update, params: { team_id: other_team.id }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("teams.errors.unauthorized_switch"))
        expect(session[:current_team_id]).not_to eq(other_team.id)
      end

      it "does not update session or cookie for unauthorized team" do
        post :update, params: { team_id: other_team.id }

        expect(session[:current_team_id]).not_to eq(other_team.id)
        expect(cookies.encrypted[:last_team_id]).not_to eq(other_team.id)
      end
    end

    context "with non-existent team" do
      it "handles not found gracefully" do
        post :update, params: { team_id: 99999 }

        expect(response).to redirect_to(teams_path)
        expect(flash[:alert]).to eq(I18n.t("teams.errors.team_not_found"))
      end

      it "does not update session for non-existent team" do
        # Set session to a known team first
        session[:current_team_id] = team_a.id

        post :update, params: { team_id: 99999 }

        # Should not be set to the invalid team ID (99999)
        expect(session[:current_team_id]).not_to eq(99999)
        # ApplicationController's set_current_team will reset to user's default
        expect(session[:current_team_id]).to eq(team_a.id)
      end
    end

    context "JSON requests" do
      it "returns JSON response on successful switch" do
        post :update, params: { team_id: team_a.id }, format: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['team']['id']).to eq(team_a.id)
        expect(json_response['team']['name']).to eq(team_a.name)
      end

      it "returns JSON error on unauthorized access" do
        post :update, params: { team_id: other_team.id }, format: :json

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq(I18n.t("teams.errors.unauthorized_switch"))
      end

      it "returns JSON error on non-existent team" do
        post :update, params: { team_id: 99999 }, format: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq(I18n.t("teams.errors.team_not_found"))
      end

      it "includes team role in successful JSON response" do
        post :update, params: { team_id: team_a.id }, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['team']['role']).to eq('owner')
      end
    end

    context "internationalization" do
      let(:team) { create(:team, name: "Test Team") }

      before do
        create(:membership, user: user, team: team, role: :member)
      end

      context "with English locale" do
        before { I18n.locale = :en }

        it "shows English success message" do
          post :update, params: { team_id: team.id }
          expect(flash[:notice]).to eq("Successfully switched to Test Team")
        end
      end

      context "with Spanish locale" do
        before do
          session[:locale] = "es"
        end

        it "shows Spanish success message" do
          post :update, params: { team_id: team.id }
          expect(flash[:notice]).to eq("Cambiado exitosamente a Test Team")
        end
      end

      context "with Danish locale" do
        before do
          session[:locale] = "da"
        end

        it "shows Danish success message" do
          post :update, params: { team_id: team.id }
          expect(flash[:notice]).to eq("Skiftet til Test Team med succes")
        end
      end
    end
  end
end
