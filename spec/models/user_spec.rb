require 'rails_helper'

RSpec.describe User, type: :model do
  let(:valid_auth0_info) do
    {
      "sub" => "auth0|123456789",
      "name" => "John Doe",
      "email" => "john@example.com"
    }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:auth0_sub) }
    it { is_expected.to validate_uniqueness_of(:auth0_sub) }
    it { is_expected.to validate_length_of(:display_name).is_at_least(2).is_at_most(100) }
    it { is_expected.to validate_length_of(:bio).is_at_most(500) }
    it { is_expected.to validate_length_of(:company).is_at_most(100) }

    describe "phone validation" do
      it "allows valid phone numbers" do
        subject.phone = "+1 (555) 123-4567"
        expect(subject).to be_valid
      end

      it "allows blank phone numbers" do
        subject.phone = ""
        expect(subject).to be_valid
      end

      it "rejects invalid phone formats" do
        subject.phone = "invalid-phone"
        expect(subject).not_to be_valid
        expect(subject.errors[:phone]).to be_present
      end
    end

    describe "website validation" do
      it "allows valid URLs" do
        subject.website = "https://example.com"
        expect(subject).to be_valid
      end

      it "allows blank websites" do
        subject.website = ""
        expect(subject).to be_valid
      end

      it "rejects invalid URLs" do
        subject.website = "not-a-url"
        expect(subject).not_to be_valid
        expect(subject.errors[:website]).to be_present
      end
    end
  end

  describe ".find_or_create_from_auth0" do
    context "when user exists" do
      let!(:existing_user) { create(:user, auth0_sub: "auth0|123456789") }

      it "returns the existing user" do
        result = User.find_or_create_from_auth0(valid_auth0_info)
        expect(result).to eq(existing_user)
      end
    end

    context "when user doesn't exist" do
      it "creates a new user" do
        expect {
          User.find_or_create_from_auth0(valid_auth0_info)
        }.to change(User, :count).by(1)
      end

      it "sets the correct attributes" do
        user = User.find_or_create_from_auth0(valid_auth0_info)
        expect(user.auth0_sub).to eq("auth0|123456789")
        expect(user.display_name).to eq("John Doe")
        expect(user.preferences).to be_present
      end
    end
  end

  describe "#profile_complete?" do
    let(:user) { build(:user) }

    it "returns false when required fields are missing" do
      user.display_name = nil
      user.bio = nil
      user.phone = nil
      expect(user.profile_complete?).to be false
    end

    it "returns true when all required fields are present" do
      user.display_name = "John Doe"
      user.bio = "Software developer"
      user.phone = "+1234567890"
      expect(user.profile_complete?).to be true
    end
  end

  describe "#profile_completion_percentage" do
    let(:user) { build(:user, auth0_sub: "auth0|123") }

    it "calculates correct percentage with no optional fields" do
      user.display_name = nil
      user.bio = nil
      user.phone = nil
      user.website = nil
      user.company = nil
      expect(user.profile_completion_percentage).to eq(17) # 1 out of 6 fields
    end

    it "calculates correct percentage with all fields" do
      user.display_name = "John"
      user.bio = "Bio"
      user.phone = "+1234567890"
      user.website = "https://example.com"
      user.company = "Acme Corp"
      expect(user.profile_completion_percentage).to eq(100)
    end
  end

  describe "#can_update_profile?" do
    let(:user) { create(:user) }

    it "allows updates when no updates have been made" do
      expect(user.can_update_profile?).to be true
    end

    it "allows updates when under the limit" do
      user.update_columns(updated_count: 5, last_update_window: 30.minutes.ago)
      expect(user.can_update_profile?).to be true
    end

    it "blocks updates when limit is reached" do
      user.update_columns(updated_count: 10, last_update_window: 30.minutes.ago)
      expect(user.can_update_profile?).to be false
    end

    it "resets after an hour" do
      user.update_columns(updated_count: 10, last_update_window: 2.hours.ago)
      expect(user.can_update_profile?).to be true
    end
  end

  describe "#updates_remaining" do
    let(:user) { create(:user) }

    it "returns 10 for new users" do
      expect(user.updates_remaining).to eq(10)
    end

    it "returns correct remaining count" do
      user.update_columns(updated_count: 3, last_update_window: 30.minutes.ago)
      expect(user.updates_remaining).to eq(7)
    end

    it "resets to 10 after window expires" do
      user.update_columns(updated_count: 10, last_update_window: 2.hours.ago)
      expect(user.updates_remaining).to eq(10)
    end
  end

  describe "rate limiting" do
    let(:user) { create(:user) }

    it "increments update count on profile changes" do
      expect {
        user.update!(display_name: "New Name")
      }.to change { user.reload.updated_count }.by(1)
    end

    it "blocks updates when limit is exceeded" do
      user.update_columns(updated_count: 10, last_update_window: 30.minutes.ago)

      user.display_name = "New Name"
      expect(user.save).to be false
      expect(user.errors[:base]).to include("Profile update limit exceeded. Try again later.")
    end

    it "doesn't increment count for non-profile fields" do
      expect {
        user.touch(:updated_at)
      }.not_to change { user.reload.updated_count }
    end
  end

  describe "profile completion tracking" do
    let(:user) { create(:user) }

    it "sets completion timestamp when profile becomes complete" do
      user.update!(
        display_name: "John Doe",
        bio: "Software developer",
        phone: "+1234567890"
      )
      expect(user.reload.profile_completed_at).to be_present
    end

    it "clears completion timestamp when profile becomes incomplete" do
      user.update!(
        display_name: "John Doe",
        bio: "Software developer",
        phone: "+1234567890"
      )
      expect(user.reload.profile_completed_at).to be_present

      user.update!(bio: nil)
      expect(user.reload.profile_completed_at).to be_nil
    end
  end
end
