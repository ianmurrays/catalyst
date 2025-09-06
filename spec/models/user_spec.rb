require 'rails_helper'

RSpec.describe User, type: :model do
  let(:valid_auth_provider_info) do
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
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.to validate_length_of(:display_name).is_at_least(2).is_at_most(100) }
    it { is_expected.to validate_length_of(:bio).is_at_most(500) }

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
  end

  describe ".find_or_create_from_auth_provider" do
    context "when user exists" do
      let!(:existing_user) { create(:user, auth0_sub: "auth0|123456789") }

      it "returns the existing user" do
        result = User.find_or_create_from_auth_provider(valid_auth_provider_info)
        expect(result).to eq(existing_user)
      end
    end

    context "when user doesn't exist" do
      it "creates a new user" do
        expect {
          User.find_or_create_from_auth_provider(valid_auth_provider_info)
        }.to change(User, :count).by(1)
      end

      it "sets the correct attributes" do
        user = User.find_or_create_from_auth_provider(valid_auth_provider_info)
        expect(user.auth0_sub).to eq("auth0|123456789")
        expect(user.display_name).to eq("John Doe")
        expect(user.email).to eq("john@example.com")
        expect(user.preferences).to be_present
      end
    end

    context "when email is missing from auth provider" do
      let(:auth_info_without_email) do
        {
          "sub" => "auth0|123456789",
          "name" => "John Doe"
        }
      end

      it "raises an ArgumentError" do
        expect {
          User.find_or_create_from_auth_provider(auth_info_without_email)
        }.to raise_error(ArgumentError, /Email is required from authentication provider/)
      end

      it "does not create a user" do
        expect {
          User.find_or_create_from_auth_provider(auth_info_without_email) rescue nil
        }.not_to change(User, :count)
      end
    end

    context "when email is blank from auth provider" do
      let(:auth_info_with_blank_email) do
        {
          "sub" => "auth0|123456789",
          "name" => "John Doe",
          "email" => ""
        }
      end

      it "raises an ArgumentError" do
        expect {
          User.find_or_create_from_auth_provider(auth_info_with_blank_email)
        }.to raise_error(ArgumentError, /Email is required from authentication provider/)
      end
    end
  end
end
