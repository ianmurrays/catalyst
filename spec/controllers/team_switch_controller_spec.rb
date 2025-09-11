# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSwitchController, type: :controller do
  let(:user) { create(:user) }
  let(:team_a) { create(:team) }
  let(:team_b) { create(:team) }
  let(:other_team) { create(:team) }

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
    it "switches current team, updates session and cookie, resets pundit context, and redirects back" do
      request.env["HTTP_REFERER"] = "/previous"

      expect(controller).to receive(:pundit_reset!).and_call_original

      post :update, params: { team_id: team_b.id }

      expect(session[:current_team_id]).to eq(team_b.id)
      expect(cookies.encrypted[:last_team_id]).to eq(team_b.id)
      expect(response).to redirect_to("/previous")
    end

    it "uses consistent cookie settings via store_team_preference method" do
      post :update, params: { team_id: team_a.id }

      expect(cookies.encrypted[:last_team_id]).to eq(team_a.id)
    end

    it "redirects to team path when no referrer" do
      post :update, params: { team_id: team_a.id }

      expect(response).to redirect_to(team_path(team_a))
    end

    it "forbids switching to a team the user is not a member of" do
      post :update, params: { team_id: other_team.id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      expect(session[:current_team_id]).not_to eq(other_team.id)
    end
  end
end
