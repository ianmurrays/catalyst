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

  describe "avatar functionality" do
    let(:user) { create(:user) }

    describe "attachment" do
      it "has an avatar attachment" do
        expect(user).to respond_to(:avatar)
      end

      it "can attach an avatar" do
        avatar_file = fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg")
        user.avatar.attach(avatar_file)
        expect(user.avatar).to be_attached
      end
    end

    describe "validations" do
      it "validates avatar content type to be an image" do
        invalid_file = fixture_file_upload("spec/fixtures/files/document.pdf", "application/pdf")
        user.avatar.attach(invalid_file)
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("must be a JPEG, PNG, or WebP image")
      end

      it "validates avatar file size to be under 5MB" do
        # This would need a large test file in real implementation
        # For now, we'll test the validation exists
        user.avatar.attach(io: StringIO.new("x" * 6.megabytes), filename: "large.jpg", content_type: "image/jpeg")
        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("must be smaller than 5MB")
      end

      it "allows valid image files" do
        valid_file = fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg")
        user.avatar.attach(valid_file)
        expect(user).to be_valid
      end

      it "detects MIME type spoofing - PDF with image MIME type" do
        # Create a fake file that looks like a PDF but claims to be an image
        user.avatar.attach(io: StringIO.new("fake content"), filename: "fake.jpg", content_type: "image/jpeg")

        # Mock only the Marcel detection to return PDF type
        allow(user.avatar).to receive(:open).and_yield(StringIO.new("fake content"))
        allow(Marcel::Magic).to receive(:by_magic).and_return(double(type: "application/pdf"))

        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("file content doesn't match the expected image format")
      end

      it "handles file processing errors gracefully" do
        user.avatar.attach(io: StringIO.new("fake content"), filename: "test.jpg", content_type: "image/jpeg")

        # Mock Marcel to raise an error during file processing
        allow(user.avatar).to receive(:open).and_yield(StringIO.new("fake content"))
        allow(Marcel::Magic).to receive(:by_magic).and_raise(StandardError.new("Processing failed"))

        expect(user).not_to be_valid
        expect(user.errors[:avatar]).to include("could not be processed")
      end
    end

    describe "variants" do
      before do
        user.save!
        avatar_file = fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg")
        user.avatar.attach(avatar_file)
      end

      it "generates thumb variant" do
        expect(user.avatar.variant(:thumb)).to be_present
      end

      it "generates small variant" do
        expect(user.avatar.variant(:small)).to be_present
      end

      it "generates medium variant" do
        expect(user.avatar.variant(:medium)).to be_present
      end

      it "generates large variant" do
        expect(user.avatar.variant(:large)).to be_present
      end

      it "generates xlarge variant" do
        expect(user.avatar.variant(:xlarge)).to be_present
      end
    end

    describe "#picture_url" do
      context "when avatar is attached" do
        before do
          user.save!
          avatar_file = fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg")
          user.avatar.attach(avatar_file)
        end

        it "returns the avatar URL instead of auth provider picture" do
          # Mock auth provider picture URL
          allow(user).to receive(:auth_provider_user_info).and_return({ "picture" => "https://auth0.com/avatar.jpg" })

          expect(user.picture_url).to include("avatar")
          expect(user.picture_url).not_to include("auth0.com")
        end
      end

      context "when no avatar is attached" do
        it "falls back to auth provider picture URL" do
          allow(user).to receive(:auth_provider_user_info).and_return({ "picture" => "https://auth0.com/avatar.jpg" })

          expect(user.picture_url).to eq("https://auth0.com/avatar.jpg")
        end

        it "returns nil when no auth provider picture" do
          allow(user).to receive(:auth_provider_user_info).and_return({})

          expect(user.picture_url).to be_nil
        end
      end
    end

    describe "#avatar_url" do
      context "when avatar is attached" do
        before do
          user.save!
          avatar_file = fixture_file_upload("spec/fixtures/files/avatar.jpg", "image/jpeg")
          user.avatar.attach(avatar_file)
        end

        it "returns default variant URL when no variant specified" do
          url = user.avatar_url
          expect(url).to be_present
          expect(url).to include("avatar")
        end

        it "returns specific variant URL when variant specified" do
          url = user.avatar_url(:thumb)
          expect(url).to be_present
          expect(url).to include("avatar")
        end
      end

      context "when no avatar is attached" do
        it "returns nil" do
          expect(user.avatar_url).to be_nil
        end

        it "returns nil for variant" do
          expect(user.avatar_url(:thumb)).to be_nil
        end
      end
    end
  end
end
