# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamContext, type: :controller do
  controller(ApplicationController) do
    include TeamContext

    def index
      render plain: "success"
    end

    # Override to skip the normal team-setting behavior in ApplicationController
    # so we can test the TeamContext concern in isolation
    private

    def set_current_team
      # Allow manual setting for test purposes
    end
  end

  include AuthHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

  before do
    login_as(user)
    session[:current_team_id] = team.id
    # Manually set current team for testing TeamContext in isolation
    controller.instance_variable_set(:@current_team, team)
  end

  describe "#require_team" do
    context "when user has current team" do
      it "allows access" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "when user has no current team" do
      before do
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
      end

      it "redirects to teams path" do
        get :index
        expect(response).to redirect_to(teams_path)
      end

      it "sets alert message" do
        get :index
        expect(flash[:alert]).to eq(I18n.t("teams.errors.no_team_selected"))
      end
    end
  end

  describe "#current_user_role" do
    it "returns user's role in current team" do
      expect(controller.current_user_role).to eq('admin')
    end

    context "when user has no membership" do
      before { membership.destroy }

      it "returns nil" do
        expect(controller.current_user_role).to be_nil
      end
    end

    context "when not logged in" do
      before do
        logout
        controller.instance_variable_set(:@current_team, nil)
      end

      it "returns nil" do
        expect(controller.current_user_role).to be_nil
      end
    end
  end

  describe "#can_manage_team?" do
    context "when user is admin" do
      it "returns true" do
        expect(controller.can_manage_team?).to be true
      end
    end

    context "when user is owner" do
      before { membership.update!(role: 'owner') }

      it "returns true" do
        expect(controller.can_manage_team?).to be true
      end
    end

    context "when user is member" do
      before { membership.update!(role: 'member') }

      it "returns false" do
        expect(controller.can_manage_team?).to be false
      end
    end

    context "when user is viewer" do
      before { membership.update!(role: 'viewer') }

      it "returns false" do
        expect(controller.can_manage_team?).to be false
      end
    end
  end

  describe "#can_edit_team_settings?" do
    context "when user is owner" do
      before { membership.update!(role: 'owner') }

      it "returns true" do
        expect(controller.can_edit_team_settings?).to be true
      end
    end

    context "when user is admin" do
      it "returns false" do
        expect(controller.can_edit_team_settings?).to be false
      end
    end

    context "when user is member" do
      before { membership.update!(role: 'member') }

      it "returns false" do
        expect(controller.can_edit_team_settings?).to be false
      end
    end
  end

  describe "#team_scoped_path" do
    it "generates team-scoped paths for strings" do
      expect(controller.team_scoped_path("/projects")).to eq("/teams/#{team.id}/projects")
    end

    it "returns original path when no current team" do
      session[:current_team_id] = nil
      controller.instance_variable_set(:@current_team, nil)
      expect(controller.team_scoped_path("/projects")).to eq("/projects")
    end

    it "handles root path" do
      expect(controller.team_scoped_path("/")).to eq("/teams/#{team.id}/")
    end
  end

  describe "#pundit_user" do
    it "returns UserContext with current user and team" do
      pundit_user = controller.pundit_user
      expect(pundit_user).to be_a(UserContext)
      expect(pundit_user.user).to eq(user)
      expect(pundit_user.team).to eq(team)
    end
  end

  describe "helper methods" do
    it "makes team_scoped_path available as helper method" do
      expect(controller.class._helper_methods).to include(:team_scoped_path)
    end

    it "makes current_user_role available as helper method" do
      expect(controller.class._helper_methods).to include(:current_user_role)
    end

    it "makes can_manage_team? available as helper method" do
      expect(controller.class._helper_methods).to include(:can_manage_team?)
    end
  end

  describe "scoping utilities" do
    # Create a mock ActiveRecord relation for testing
    let(:mock_relation) do
      double("ActiveRecord::Relation").tap do |relation|
        allow(relation).to receive(:where).with(team: team).and_return(relation)
      end
    end

    describe "#scope_to_current_team" do
      it "scopes relation to current team" do
        expect(mock_relation).to receive(:where).with(team: team)
        controller.scope_to_current_team(mock_relation)
      end

      it "returns original relation when no current team" do
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
        result = controller.scope_to_current_team(mock_relation)
        expect(result).to eq(mock_relation)
      end
    end

    describe "#build_for_current_team" do
      # Create a mock model class for testing
      let(:mock_model_class) do
        double("ModelClass").tap do |klass|
          allow(klass).to receive(:name).and_return("Invitation")
          allow(klass).to receive(:new).with({ name: "Test" }).and_return(double("instance"))
        end
      end

      it "builds model through team association when team present" do
        # Use real association that exists on Team
        expect(team.invitations).to receive(:build).with({ name: "Test" })
        controller.build_for_current_team(mock_model_class, name: "Test")
      end

      it "builds model directly when no current team" do
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
        expect(mock_model_class).to receive(:new).with({ name: "Test" })
        controller.build_for_current_team(mock_model_class, name: "Test")
      end
    end

    describe "#team_scoped_url_for" do
      before do
        # Mock url_for to avoid routing complexity in tests
        allow(controller).to receive(:url_for).and_return("/mocked_url")
      end

      it "adds team_id to hash options" do
        expect(controller).to receive(:url_for).with({ controller: "projects", team_id: team.id })
        controller.team_scoped_url_for(controller: "projects")
      end

      it "passes through non-hash options when no team" do
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
        expect(controller).to receive(:url_for).with("some_path")
        controller.team_scoped_url_for("some_path")
      end
    end

    describe "#team_breadcrumb_items" do
      before do
        # Mock path helpers
        allow(controller).to receive(:teams_path).and_return("/teams")
        allow(controller).to receive(:team_path).with(team).and_return("/teams/#{team.id}")
      end

      it "returns breadcrumb items with team context" do
        items = controller.team_breadcrumb_items

        expect(items).to be_an(Array)
        expect(items.length).to eq(2)

        expect(items[0]).to include(name: I18n.t("navigation.teams"), path: "/teams")
        expect(items[1]).to include(name: team.name, path: "/teams/#{team.id}")
      end

      it "returns empty array when no current team" do
        session[:current_team_id] = nil
        controller.instance_variable_set(:@current_team, nil)
        expect(controller.team_breadcrumb_items).to eq([])
      end
    end
  end
end
