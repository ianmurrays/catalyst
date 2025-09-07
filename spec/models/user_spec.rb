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

    it "validates preferences using store_model" do
      subject.preferences = UserPreferences.new
      expect(subject).to be_valid
    end

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
        expect(user.preferences).to be_a(UserPreferences)
        expect(user.language).to eq("en")  # Uses User model default logic
        expect(user.timezone).to eq("UTC")
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

  describe "language preferences" do
    let(:user) { build(:user) }

    describe "#available_languages" do
      it "delegates to LocaleService" do
        expected_options = [ [ "English", "en" ], [ "Español (Spanish)", "es" ] ]
        allow(LocaleService).to receive(:language_options).and_return(expected_options)

        expect(user.available_languages).to eq(expected_options)
        expect(LocaleService).to have_received(:language_options)
      end
    end

    describe "#language" do
      it "returns language from preferences" do
        user.preferences.language = "es"
        expect(user.language).to eq("es")
      end

      it "returns default language when not set in preferences" do
        expect(user.language).to eq("en")
      end
    end

    describe "#language=" do
      it "sets language in preferences" do
        user.language = "es"
        expect(user.preferences.language).to eq("es")
      end
    end

    describe "language preference validation" do
      it "validates language through preferences model" do
        allow(LocaleService).to receive(:available_locales).and_return([ :en, :es, :da ])

        user.language = "fr"
        expect(user).not_to be_valid
        expect(user.errors.full_messages.any? { |msg| msg.include?("invalid") }).to be true
      end

      it "allows valid language codes" do
        allow(LocaleService).to receive(:available_locales).and_return([ :en, :es, :da ])

        user.language = "es"
        expect(user).to be_valid
      end
    end
  end

  describe "timezone preferences" do
    let(:user) { build(:user) }

    describe "#timezone" do
      it "returns timezone from preferences" do
        user.preferences.timezone = "Eastern Time (US & Canada)"
        expect(user.timezone).to eq("Eastern Time (US & Canada)")
      end

      it "returns default timezone when not set in preferences" do
        expect(user.timezone).to eq("UTC")
      end
    end

    describe "#timezone=" do
      it "sets timezone in preferences" do
        user.timezone = "Eastern Time (US & Canada)"
        expect(user.preferences.timezone).to eq("Eastern Time (US & Canada)")
      end

      it "preserves other preferences when setting timezone" do
        user.preferences.language = "es"
        user.timezone = "Central Time (US & Canada)"
        expect(user.preferences.language).to eq("es")
        expect(user.preferences.timezone).to eq("Central Time (US & Canada)")
      end
    end

    describe "timezone preference validation" do
      it "validates timezone through preferences model" do
        user.timezone = "Invalid/Timezone"
        expect(user).not_to be_valid
        expect(user.errors.full_messages.any? { |msg| msg.include?("invalid") }).to be true
      end

      it "allows valid timezone identifiers" do
        user.timezone = "Eastern Time (US & Canada)"
        expect(user).to be_valid
      end

      it "allows UTC timezone" do
        user.timezone = "UTC"
        expect(user).to be_valid
      end
    end

    describe "#timezone_object" do
      it "returns ActiveSupport::TimeZone object for current timezone" do
        user.preferences.timezone = "Eastern Time (US & Canada)"
        timezone_obj = user.timezone_object

        expect(timezone_obj).to be_a(ActiveSupport::TimeZone)
        expect(timezone_obj.name).to eq("Eastern Time (US & Canada)")
      end

      it "returns UTC timezone object when timezone is not set" do
        timezone_obj = user.timezone_object

        expect(timezone_obj).to be_a(ActiveSupport::TimeZone)
        expect(timezone_obj.name).to eq("UTC")
      end

      it "returns nil when timezone identifier is invalid" do
        user.preferences.timezone = "Invalid/Timezone"
        timezone_obj = user.timezone_object

        expect(timezone_obj).to be_nil
      end
    end
  end
end
