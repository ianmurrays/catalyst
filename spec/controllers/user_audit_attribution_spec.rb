require 'rails_helper'

RSpec.describe "User audit attribution", type: :controller do
  include AuthHelpers

  controller(ApplicationController) do
    include AuthProvider
    include Secured

    def update_user
      current_user.update!(params.permit(:display_name, :bio, :phone))
      render json: { status: "success" }
    end

    def update_other_user
      user = User.find(params[:id])
      user.update!(params.permit(:display_name, :bio, :phone))
      render json: { status: "success" }
    end
  end

  before do
    routes.draw do
      patch "update_user" => "anonymous#update_user"
      patch "update_other_user/:id" => "anonymous#update_other_user"
    end
  end

  describe "current_user attribution in audits" do
    let(:user) { create(:user, display_name: "Original Name") }
    let(:other_user) { create(:user, display_name: "Other User") }

    context "when user is authenticated" do
      before { login_as(user) }

      it "records the current_user in audit when user updates themselves" do
        patch :update_user, params: { display_name: "Self Updated" }

        audit = user.reload.audits.last
        expect(audit.user).to eq(user)
        expect(audit.user_id).to eq(user.id)
        expect(audit.user_type).to eq("User")
      end

      it "records the current_user in audit when user updates another user" do
        patch :update_other_user, params: {
          id: other_user.id,
          display_name: "Updated by Other"
        }

        audit = other_user.reload.audits.last
        expect(audit.user).to eq(user)  # The current_user who made the change
        expect(audit.user_id).to eq(user.id)
        expect(audit.auditable).to eq(other_user)  # The user who was changed
      end

      it "maintains user attribution across multiple changes" do
        initial_count = user.audits.count

        # Use the audited gem's as_user method to simulate the user context
        Audited.audit_class.as_user(user) do
          user.update!(display_name: "First Change")
          user.update!(bio: "Second Change")
        end

        # Get the new audits created during our test
        new_audits = user.reload.audits.order(:version).last(2)
        expect(new_audits.count).to eq(2)
        new_audits.each do |audit|
          expect(audit.user).to eq(user)
        end
      end
    end

    context "when no user is authenticated" do
      it "creates audit with nil user for unauthenticated actions" do
        # Simulate system-level changes without authentication
        User.auditing_enabled = true
        other_user.update!(display_name: "System Update")

        audit = other_user.audits.last
        expect(audit.user).to be_nil
        expect(audit.user_id).to be_nil
        expect(audit.user_type).to be_nil
      end
    end
  end

  describe "audit user context in different controller scenarios" do
    let(:admin_user) { create(:user, display_name: "Admin User") }
    let(:regular_user) { create(:user, display_name: "Regular User") }

    it "correctly attributes audits when switching user contexts" do
      # First user makes a change
      login_as(admin_user)
      patch :update_user, params: { display_name: "Admin Change" }
      admin_audit = admin_user.reload.audits.last

      # Second user makes a change
      login_as(regular_user)
      patch :update_user, params: { display_name: "Regular Change" }
      regular_audit = regular_user.reload.audits.last

      expect(admin_audit.user).to eq(admin_user)
      expect(regular_audit.user).to eq(regular_user)
    end

    it "tracks user changes in profile controller context" do
      # Use the audited gem's as_user method to simulate authenticated context
      Audited.audit_class.as_user(regular_user) do
        expect {
          regular_user.update!(
            display_name: "Profile Updated",
            bio: "New bio from profile"
          )
        }.to change(regular_user.audits, :count).by(1)
      end

      audit = regular_user.audits.last
      expect(audit.user).to eq(regular_user)
      expect(audit.audited_changes.keys).to contain_exactly("display_name", "bio")
    end
  end

  describe "audit user information storage" do
    let(:test_user) { create(:user, display_name: "Test User", email: "test@example.com") }

    before { login_as(test_user) }

    it "stores user reference correctly" do
      patch :update_user, params: { display_name: "Reference Test" }

      audit = test_user.reload.audits.last
      expect(audit.user).to be_a(User)
      expect(audit.user.id).to eq(test_user.id)
      expect(audit.user.email).to eq(test_user.email)
    end

    it "allows querying audits by user" do
      patch :update_user, params: { display_name: "Query Test 1" }
      patch :update_user, params: { bio: "Query Test 2" }

      user_audits = Audited::Audit.where(user: test_user)
      expect(user_audits.count).to be >= 2
      user_audits.each do |audit|
        expect(audit.user_id).to eq(test_user.id)
      end
    end

    it "supports finding all changes made by a specific user" do
      other_user = create(:user)
      login_as(test_user)

      # Current user updates themselves
      patch :update_user, params: { display_name: "Self Update" }

      # Current user updates another user
      patch :update_other_user, params: {
        id: other_user.id,
        display_name: "Updated Other User"
      }

      # Find all changes made by test_user
      changes_by_user = Audited::Audit.where(user: test_user)
      expect(changes_by_user.count).to be >= 2

      # Verify both self-updates and other-user updates are tracked
      auditable_ids = changes_by_user.pluck(:auditable_id)
      expect(auditable_ids).to include(test_user.id, other_user.id)
    end
  end
end
