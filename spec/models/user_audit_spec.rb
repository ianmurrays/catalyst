require 'rails_helper'

RSpec.describe User, "auditing", type: :model do
  let(:user) { create(:user) }

  describe "audited configuration" do
    it "has auditing enabled" do
      expect(User.auditing_enabled).to be true
    end

    it "responds to audit methods" do
      expect(user).to respond_to(:audits)
      expect(User).to respond_to(:with_auditing)
    end
  end

  describe "audit creation" do
    describe "on user creation" do
      it "creates an audit record for new users" do
        expect {
          create(:user, email: "new@example.com", display_name: "New User")
        }.to change(Audited::Audit, :count).by(1)
      end

      it "records correct audit information for creation" do
        new_user = create(:user, email: "audit@example.com", display_name: "Audit User")
        audit = new_user.audits.last

        expect(audit.action).to eq("create")
        expect(audit.auditable_type).to eq("User")
        expect(audit.auditable_id).to eq(new_user.id)
        expect(audit.version).to eq(1)
      end

      it "includes audited fields in creation audit" do
        new_user = create(:user,
          email: "test@example.com",
          display_name: "Test User",
          bio: "A test user bio",
          phone: "+1 555-123-4567"
        )
        audit = new_user.audits.last

        expect(audit.audited_changes).to include("email")
        expect(audit.audited_changes).to include("display_name")
        expect(audit.audited_changes).to include("bio")
        expect(audit.audited_changes).to include("phone")
      end

      it "excludes sensitive fields from creation audit" do
        new_user = create(:user,
          auth0_sub: "auth0|sensitive123",
          preferences: UserPreferences.new(language: "es", timezone: "UTC")
        )
        audit = new_user.audits.last

        expect(audit.audited_changes).not_to include("auth0_sub")
        expect(audit.audited_changes).to include("preferences")
      end
    end

    describe "on user update" do
      it "creates an audit record for user updates" do
        expect {
          user.update!(display_name: "Updated Name")
        }.to change(user.audits, :count).by(1)
      end

      it "records correct audit information for updates" do
        original_name = user.display_name
        user.update!(display_name: "Updated Name")
        audit = user.audits.last

        expect(audit.action).to eq("update")
        expect(audit.auditable_type).to eq("User")
        expect(audit.auditable_id).to eq(user.id)
        expect(audit.version).to eq(2)
        expect(audit.audited_changes).to eq({
          "display_name" => [ original_name, "Updated Name" ]
        })
      end

      it "tracks multiple field changes" do
        user.update!(
          display_name: "Multi Change User",
          bio: "Updated bio content",
          phone: "+1 555-999-8888"
        )
        audit = user.audits.last

        expect(audit.audited_changes.keys).to contain_exactly("display_name", "bio", "phone")
      end

      it "does not include excluded fields in audit changes" do
        # Direct auth0_sub updates should not appear in audited_changes
        user.update!(display_name: "Test Update", auth0_sub: "auth0|new_id")
        audit = user.audits.last

        expect(audit.audited_changes).to include("display_name")
        expect(audit.audited_changes).not_to include("auth0_sub")
      end

      it "includes preferences changes in audit changes" do
        # Preferences changes should now appear in audited_changes
        user.update!(display_name: "Preference Test", preferences: UserPreferences.new(language: "es", timezone: "UTC"))
        audit = user.audits.last

        expect(audit.audited_changes).to include("display_name")
        expect(audit.audited_changes).to include("preferences")
      end

      it "creates audit for both non-excluded fields when mixed update" do
        user.update!(
          display_name: "Mixed Update",
          preferences: UserPreferences.new(language: "da", timezone: "UTC")
        )
        audit = user.audits.last

        expect(audit.audited_changes.keys).to contain_exactly("display_name", "preferences")
        expect(audit.audited_changes).to include("preferences")
      end
    end

    describe "on user destroy" do
      it "creates an audit record for user deletion" do
        user_to_delete = create(:user)

        expect {
          user_to_delete.destroy!
        }.to change(Audited::Audit, :count).by(1)
      end

      it "records correct audit information for deletion" do
        user_to_delete = create(:user, display_name: "To Be Deleted")
        user_id = user_to_delete.id
        user_to_delete.destroy!

        audit = Audited::Audit.where(auditable_id: user_id, auditable_type: "User").last
        expect(audit.action).to eq("destroy")
        expect(audit.auditable_id).to eq(user_id)
      end
    end
  end

  describe "audit history and revisions" do
    it "maintains audit version incrementing" do
      user.update!(display_name: "Version 2")
      user.update!(bio: "Version 3")
      user.update!(phone: "+1 555-444-3333")

      audits = user.audits.order(:version)
      expect(audits.map(&:version)).to eq([ 1, 2, 3, 4 ])
    end

    it "provides access to revision history" do
      original_name = user.display_name
      user.update!(display_name: "Revised Name")

      expect(user.revisions).to be_present
      expect(user.revision(1).display_name).to eq(original_name)
      expect(user.revision(2).display_name).to eq("Revised Name")
    end
  end

  describe "audit querying" do
    before do
      user.update!(display_name: "First Update")
      user.update!(bio: "Second Update")
      user.update!(phone: "+1 555-777-9999")
    end

    it "allows querying audits by action" do
      create_audits = user.audits.where(action: "create")
      update_audits = user.audits.where(action: "update")

      expect(create_audits.count).to eq(1)
      expect(update_audits.count).to eq(3)
    end

    it "allows querying audits by date range" do
      recent_audits = user.audits.where("created_at >= ?", 1.minute.ago)
      expect(recent_audits.count).to be >= 3
    end

    it "provides audit changes information" do
      last_audit = user.audits.last
      expect(last_audit.audited_changes).to be_a(Hash)
      expect(last_audit.audited_changes.keys).to include("phone")
    end
  end

  describe "edge cases and validation" do
    it "handles validation failures gracefully" do
      user.email = "invalid-email"

      expect {
        user.save
      }.not_to change(Audited::Audit, :count)
    end

    it "creates audit for successful save after validation fix" do
      user.email = "invalid-email"
      user.save # This should fail validation

      user.email = "valid@example.com"
      expect {
        user.save!
      }.to change(user.audits, :count).by(1)
    end

    it "handles large text field changes" do
      large_bio = "x" * 500  # Adjust to fit User model validation
      user.update!(bio: large_bio)
      audit = user.audits.last

      expect(audit.audited_changes["bio"][1]).to eq(large_bio)
    end
  end
end
