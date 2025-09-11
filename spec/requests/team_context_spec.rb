# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Team Context", type: :request do
  let(:user) { create(:user) }
  let(:team_a) { create(:team) }
  let(:team_b) { create(:team) }

  before do
    create(:membership, user: user, team: team_a, role: :owner)
    create(:membership, user: user, team: team_b, role: :member)
  end

  # Stub authentication for request specs to avoid OmniAuth CSRF requirements
  before do
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  def login
    # No-op: authentication is stubbed above
  end

  describe "login with saved preference" do
    it "uses cookies.encrypted[:last_team_id] to set session current team after login" do
      cookies[:last_team_id] = team_b.id

      login
      get "/"

      expect(session[:current_team_id]).to eq(team_b.id)
    end
  end

  describe "switching teams" do
    it "updates session and cookie, and redirects appropriately" do
      login
      # referer to test redirect back behavior
      get "/", headers: { "HTTP_REFERER" => "/profile" }

      post switch_team_path(team_id: team_b.id), headers: { "HTTP_REFERER" => "/profile" }
      expect(response).to redirect_to("/profile")

      follow_redirect! if response.redirect?

      expect(session[:current_team_id]).to eq(team_b.id)
      expect(cookies[:last_team_id]).to be_present
    end

    it "prevents switching to a team the user is not a member of" do
      other_team = create(:team) # no membership for user
      login

      post switch_team_path(team_id: other_team.id)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      expect(session[:current_team_id]).not_to eq(other_team.id)
    end
  end

  describe "cookie persistence and logout behavior" do
    it "sets last_team_id cookie on switch, and clears it on logout" do
      login

      post switch_team_path(team_id: team_a.id)
      expect(cookies[:last_team_id]).to be_present

      delete "/auth/logout"
      expect(response).to redirect_to(%r{\Ahttps://}) # external logout

      # last_team cookie cleared for security (session fixation mitigation)
      expect(cookies[:last_team_id]).to be_blank
    end
  end

  describe "fallback behavior when no session or cookie" do
    it "defaults to first available team for the user" do
      # Simulate a fresh login without preference cookie
      cookies.delete(:last_team_id)
      login

      get "/"
      expect(session[:current_team_id]).to be_present
      expect([ team_a.id, team_b.id ]).to include(session[:current_team_id])
    end
  end
end
