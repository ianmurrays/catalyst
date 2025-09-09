require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "validations" do
    subject { build(:invitation) }

    it { is_expected.to validate_presence_of(:team) }
    # Token is auto-generated, so presence validation is not needed
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:created_by) }
    it { is_expected.to validate_uniqueness_of(:token) }

    describe "role validation" do
      it "allows valid roles" do
        %w[owner admin member viewer].each do |role|
          invitation = build(:invitation, role: role)
          expect(invitation).to be_valid
        end
      end

      it "rejects invalid roles" do
        invitation = build(:invitation)
        expect {
          invitation.role = "invalid_role"
        }.to raise_error(ArgumentError, "'invalid_role' is not a valid role")
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:created_by).class_name('User') }
    it { is_expected.to belong_to(:used_by).class_name('User').optional }
  end

  describe "role enum" do
    it "defines role enum correctly" do
      expect(Invitation.roles).to eq({
        "owner" => 0,
        "admin" => 1,
        "member" => 2,
        "viewer" => 3
      })
    end

    it "defaults to member role" do
      invitation = Invitation.new
      expect(invitation.role).to eq("member")
    end
  end

  describe "token generation" do
    describe "on create" do
      it "generates a unique token" do
        invitation = build(:invitation, token: nil)
        invitation.save!
        expect(invitation.token).to be_present
        expect(invitation.token.length).to be >= 20
      end

      it "does not overwrite existing token" do
        original_token = "existing-token"
        invitation = build(:invitation, token: original_token)
        invitation.save!
        expect(invitation.token).to eq(original_token)
      end

      it "ensures token uniqueness" do
        existing_token = create(:invitation).token
        invitation = build(:invitation, token: nil)

        allow(SecureRandom).to receive(:urlsafe_base64).and_return(existing_token, "unique-token")
        invitation.save!

        expect(invitation.token).to eq("unique-token")
      end
    end
  end

  describe "scopes" do
    let!(:active_invitation) { create(:invitation) }
    let!(:expired_invitation) { create(:invitation, :expired) }
    let!(:used_invitation) { create(:invitation, :used) }
    let!(:never_expires_invitation) { create(:invitation, :never_expires) }

    describe ".active" do
      it "returns invitations that are not used and not expired" do
        expect(Invitation.active).to include(active_invitation, never_expires_invitation)
        expect(Invitation.active).not_to include(expired_invitation, used_invitation)
      end
    end

    describe ".expired" do
      it "returns invitations that are expired and not used" do
        expect(Invitation.expired).to include(expired_invitation)
        expect(Invitation.expired).not_to include(active_invitation, used_invitation, never_expires_invitation)
      end
    end

    describe ".used" do
      it "returns invitations that have been used" do
        expect(Invitation.used).to include(used_invitation)
        expect(Invitation.used).not_to include(active_invitation, expired_invitation, never_expires_invitation)
      end
    end

    describe ".by_team" do
      let(:team1) { create(:team) }
      let(:team2) { create(:team) }
      let!(:team1_invitation) { create(:invitation, team: team1) }
      let!(:team2_invitation) { create(:invitation, team: team2) }

      it "filters invitations by team" do
        expect(Invitation.by_team(team1)).to include(team1_invitation)
        expect(Invitation.by_team(team1)).not_to include(team2_invitation)
      end
    end
  end

  describe "expiration logic" do
    describe "#expired?" do
      it "returns false for invitation that never expires" do
        invitation = create(:invitation, :never_expires)
        expect(invitation.expired?).to be false
      end

      it "returns false for invitation not yet expired" do
        invitation = create(:invitation, expires_at: 1.day.from_now)
        expect(invitation.expired?).to be false
      end

      it "returns true for invitation that has expired" do
        invitation = create(:invitation, expires_at: 1.day.ago)
        expect(invitation.expired?).to be true
      end
    end

    describe "#expires_in" do
      it "returns time until expiration" do
        invitation = create(:invitation, expires_at: 2.hours.from_now)
        expect(invitation.expires_in).to be_within(10.seconds).of(2.hours)
      end

      it "returns nil for invitation that never expires" do
        invitation = create(:invitation, :never_expires)
        expect(invitation.expires_in).to be_nil
      end

      it "returns negative value for expired invitation" do
        invitation = create(:invitation, expires_at: 1.hour.ago)
        expect(invitation.expires_in).to be < 0
      end
    end

    describe ".expiration_options" do
      it "returns available expiration options" do
        options = Invitation.expiration_options
        expect(options).to include(
          [ "1 hour", 1.hour ],
          [ "1 day", 1.day ],
          [ "3 days", 3.days ],
          [ "1 week", 1.week ],
          [ "Never", nil ]
        )
      end
    end

    describe "#set_expiration" do
      let(:invitation) { build(:invitation) }

      it "sets expiration from duration" do
        invitation.set_expiration(2.days)
        expect(invitation.expires_at).to be_within(1.minute).of(2.days.from_now)
      end

      it "sets no expiration when duration is nil" do
        invitation.set_expiration(nil)
        expect(invitation.expires_at).to be_nil
      end
    end
  end

  describe "invitation status" do
    describe "#used?" do
      it "returns false for unused invitation" do
        invitation = create(:invitation)
        expect(invitation.used?).to be false
      end

      it "returns true for used invitation" do
        invitation = create(:invitation, :used)
        expect(invitation.used?).to be true
      end
    end

    describe "#usable?" do
      it "returns true for active invitation" do
        invitation = create(:invitation, expires_at: 1.day.from_now)
        expect(invitation.usable?).to be true
      end

      it "returns false for expired invitation" do
        invitation = create(:invitation, :expired)
        expect(invitation.usable?).to be false
      end

      it "returns false for used invitation" do
        invitation = create(:invitation, :used)
        expect(invitation.usable?).to be false
      end

      it "returns true for never-expiring invitation" do
        invitation = create(:invitation, :never_expires)
        expect(invitation.usable?).to be true
      end
    end
  end

  describe "acceptance flow" do
    let(:invitation) { create(:invitation) }
    let(:user) { create(:user) }

    describe "#accept!" do
      context "with usable invitation" do
        it "creates membership for user" do
          expect { invitation.accept!(user) }.to change { Membership.count }.by(1)

          membership = Membership.last
          expect(membership.user).to eq(user)
          expect(membership.team).to eq(invitation.team)
          expect(membership.role).to eq(invitation.role)
        end

        it "marks invitation as used" do
          invitation.accept!(user)
          invitation.reload

          expect(invitation.used?).to be true
          expect(invitation.used_by).to eq(user)
          expect(invitation.used_at).to be_within(1.minute).of(Time.current)
        end

        it "returns the created membership" do
          membership = invitation.accept!(user)
          expect(membership).to be_a(Membership)
          expect(membership).to be_persisted
        end
      end

      context "with expired invitation" do
        let(:invitation) { create(:invitation, :expired) }

        it "raises InvitationExpired error" do
          expect { invitation.accept!(user) }.to raise_error(Invitation::InvitationExpired)
        end

        it "does not create membership" do
          expect { invitation.accept!(user) rescue nil }.not_to change { Membership.count }
        end
      end

      context "with used invitation" do
        let(:invitation) { create(:invitation, :used) }

        it "raises InvitationAlreadyUsed error" do
          expect { invitation.accept!(user) }.to raise_error(Invitation::InvitationAlreadyUsed)
        end

        it "does not create membership" do
          expect { invitation.accept!(user) rescue nil }.not_to change { Membership.count }
        end
      end

      context "when user is already a member" do
        before { create(:membership, user: user, team: invitation.team) }

        it "raises UserAlreadyMember error" do
          expect { invitation.accept!(user) }.to raise_error(Invitation::UserAlreadyMember)
        end

        it "does not create duplicate membership" do
          expect { invitation.accept!(user) rescue nil }.not_to change { Membership.count }
        end
      end
    end
  end

  describe "delegation methods" do
    let(:team) { create(:team, name: "Test Team") }
    let(:creator) { create(:user, display_name: "Creator") }
    let(:invitation) { create(:invitation, team: team, created_by: creator) }

    it "delegates to team" do
      expect(invitation.team_name).to eq("Test Team")
    end

    it "delegates to creator" do
      expect(invitation.creator_name).to eq("Creator")
    end
  end

  describe "custom exceptions" do
    it "defines custom exception classes" do
      expect(Invitation::InvitationExpired).to be < StandardError
      expect(Invitation::InvitationAlreadyUsed).to be < StandardError
      expect(Invitation::UserAlreadyMember).to be < StandardError
    end
  end
end
