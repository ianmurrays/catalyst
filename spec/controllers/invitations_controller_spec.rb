require "rails_helper"

RSpec.describe InvitationsController, type: :controller do
  let(:owner) { create(:user) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:team) { create(:team) }

  before do
    create(:membership, user: owner, team:, role: :owner)
    create(:membership, user: admin, team:, role: :admin)
    create(:membership, user: member, team:, role: :member)
  end

  def mock_auth(user)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_auth_provider_user).and_return({
      "sub" => user.auth0_sub,
      "name" => user.display_name,
      "email" => user.email
    })
  end

  describe "GET #index" do
    context "as owner" do
      before { mock_auth(owner) }

      it "renders the invitations index" do
        get :index, params: { team_id: team.slug }
        expect(response).to have_http_status(:ok)
      end
    end

    context "as member (not allowed)" do
      before { mock_auth(member) }

      it "redirects with authorization error" do
        get :index, params: { team_id: team.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end

  describe "GET #new" do
    context "as admin" do
      before { mock_auth(admin) }

      it "renders the new invitation form" do
        get :new, params: { team_id: team.slug }
        expect(response).to have_http_status(:ok)
      end
    end

    context "as member (not allowed)" do
      before { mock_auth(member) }

      it "redirects with authorization error" do
        get :new, params: { team_id: team.slug }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("pundit.not_authorized"))
      end
    end
  end

  describe "POST #create" do
    before { mock_auth(owner) }

    it "creates an invitation and renders the New view with a link" do
      post :create, params: { team_id: team.slug, invitation: { role: :member, expires_in: "1d" } }
      expect(response).to have_http_status(:created)
      expect(flash[:notice]).to eq(I18n.t("invitations.flash.created"))
      expect(Invitation.where(team: team).count).to eq(1)
    end

    it "prevents creating invitation with higher role than inviter" do
      mock_auth(admin)
      post :create, params: { team_id: team.slug, invitation: { role: :owner, expires_in: "1d" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash.now[:alert]).to be_present
    end
  end

  describe "DELETE #destroy" do
    before { mock_auth(owner) }

    it "revokes an unused invitation" do
      invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
      expect {
        delete :destroy, params: { team_id: team.slug, id: invitation.id }
      }.to change(Invitation, :count).by(-1)
      expect(response).to redirect_to(team_invitations_path(team))
      expect(flash[:notice]).to eq(I18n.t("invitations.flash.revoked"))
    end

    it "does not revoke a used invitation" do
      invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
      Teams::InvitationService.accept(token: raw, user: non_member)
      expect {
        delete :destroy, params: { team_id: team.slug, id: invitation.id }
      }.not_to change(Invitation, :count)
      expect(response).to redirect_to(team_invitations_path(team))
      expect(flash[:alert]).to eq(I18n.t("invitations.flash.already_used"))
    end
  end

  describe "GET #accept" do
    context "when not logged in" do
      it "stores token in session and redirects to auth" do
        invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
        get :accept, params: { token: raw }
        expect(session[:invitation_token]).to eq(raw)
        expect(response).to redirect_to("/login")
      end
    end

    context "when logged in" do
      before { mock_auth(non_member) }

      it "accepts the invitation and renders confirmation" do
        invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
        expect {
          get :accept, params: { token: raw }
        }.to change { team.memberships.count }.by(1)
        expect(flash[:notice]).to eq(I18n.t("invitations.flash.accepted"))
        # We render a confirmation page
        expect(response).to have_http_status(:ok)
      end

      it "handles expired invitation" do
        invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.hour)
        invitation.update!(expires_at: 1.hour.ago)
        get :accept, params: { token: raw }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("invitations.flash.expired"))
      end

      it "handles already used invitation" do
        invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
        # Use a user who is NOT already a member to consume the invitation
        used_by = create(:user)
        Teams::InvitationService.accept(token: raw, user: used_by)

        # Current logged-in user is non_member (from mock_auth), attempting to reuse the token
        get :accept, params: { token: raw }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("invitations.flash.already_used"))
      end

      it "does not accept if user already a member" do
        create(:membership, user: non_member, team:, role: :viewer)
        invitation, raw = Teams::InvitationService.create(team:, role: :member, created_by: owner, expires_in: 1.day)
        get :accept, params: { token: raw }
        expect(response).to redirect_to(team_path(team))
        expect(flash[:notice]).to eq(I18n.t("invitations.flash.already_member"))
      end
    end
  end
end
