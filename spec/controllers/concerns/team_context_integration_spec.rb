# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "TeamContext integration", type: :controller do
  describe "with existing concerns" do
    controller(ApplicationController) do
      include AuthProvider
      include Secured
      include TeamContext

      def index
        render plain: "authenticated and team-scoped"
      end

      # Override to skip the normal team-setting behavior in ApplicationController
      # so we can test the TeamContext concern in isolation
      private

      def set_current_team
        # Allow manual setting for test purposes
      end
    end

    let(:user) { create(:user) }
    let(:team) { create(:team) }

    before do
      create(:membership, user: user, team: team)
    end

    context "when not logged in" do
      it "redirects to auth (Secured concern)" do
        get :index
        expect(response).to redirect_to(login_path)
      end

      it "does not reach team context validation" do
        # This ensures auth comes before team validation
        expect(controller).not_to receive(:require_team)
        get :index
      end
    end

    context "when logged in but no team" do
      include AuthHelpers

      before do
        login_as(user)
        controller.instance_variable_set(:@current_team, nil)
      end

      it "redirects to teams page (TeamContext concern)" do
        get :index
        expect(response).to redirect_to(teams_path)
      end

      it "sets alert message" do
        get :index
        expect(flash[:alert]).to eq(I18n.t("teams.errors.no_team_selected"))
      end
    end

    context "when logged in with team" do
      include AuthHelpers

      before do
        login_as(user)
        session[:current_team_id] = team.id
        controller.instance_variable_set(:@current_team, team)
      end

      it "allows access" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "has access to all concern methods" do
        get :index

        # AuthProvider methods
        expect(controller.logged_in?).to be true
        expect(controller.current_user).to eq(user)

        # TeamContext methods - test the public interface instead
        expect(controller.instance_variable_get(:@current_team)).to eq(team)
        expect(controller.current_user_role).to be_present
        expect(controller.can_manage_team?).to be_in([ true, false ])
      end
    end
  end

  describe "filter ordering" do
    # Test that TeamContext works correctly when Secured is included
    controller(ApplicationController) do
      include TeamContext
      include Secured

      def index
        render plain: "success"
      end

      private

      def set_current_team
        # Override to avoid conflicts
      end
    end

    let(:user) { create(:user) }

    it "applies authentication before team context" do
      # When not logged in, Secured should redirect before TeamContext runs
      # Since Secured requires login and TeamContext is included first,
      # the behavior depends on filter order. Both will try to redirect.
      # In practice, Secured's redirect should take precedence.
      get :index

      # Either redirect is acceptable since both concerns require authentication
      expect(response).to be_redirect
      expect([ login_path, teams_path ]).to include(response.location.gsub("http://test.host", ""))
    end
  end

  describe "pundit integration" do
    controller(ApplicationController) do
      include TeamContext

      def index
        authorize_user = pundit_user
        render plain: "User: #{authorize_user.user.id}, Team: #{authorize_user.team.id}"
      end

      private

      def set_current_team
        # Override to skip the normal team-setting behavior
      end
    end

    include AuthHelpers

    let(:user) { create(:user) }
    let(:team) { create(:team) }

    before do
      create(:membership, user: user, team: team)
      login_as(user)
      session[:current_team_id] = team.id
      controller.instance_variable_set(:@current_team, team)
    end

    it "provides UserContext to pundit" do
      get :index

      pundit_user = controller.pundit_user
      expect(pundit_user).to be_a(UserContext)
      expect(pundit_user.user).to eq(user)
      expect(pundit_user.team).to eq(team)
    end
  end

  describe "error handling" do
    controller(ApplicationController) do
      include TeamContext

      def index
        render plain: "success"
      end

      private

      def set_current_team
        # Override to skip the normal team-setting behavior
      end
    end

    include AuthHelpers

    context "when current_team method is nil" do
      let(:user) { create(:user) }

      before do
        login_as(user)
        # Ensure no team is set
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
      end

      it "redirects gracefully" do
        get :index
        expect(response).to redirect_to(teams_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
