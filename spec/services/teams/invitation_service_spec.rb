require "rails_helper"

RSpec.describe Teams::InvitationService do
  let(:team) { create(:team) }
  let(:owner) { create(:user) }
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:invitee) { create(:user) }

  before do
    create(:membership, user: owner, team:, role: :owner)
    create(:membership, user: admin, team:, role: :admin)
    create(:membership, user: member, team:, role: :member)
  end

  describe ".create" do
    it "creates an invitation with a hashed token and returns the raw token" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.day)

      expect(invitation).to be_persisted
      expect(raw_token).to be_present
      expect(invitation.token).to eq(described_class.digest(raw_token))
      expect(invitation.role).to eq("member")
      expect(invitation.expires_at).to be_present
    end

    it "supports never expiring invitations when expires_in is nil" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: nil)

      expect(invitation).to be_persisted
      expect(raw_token).to be_present
      expect(invitation.expires_at).to be_nil
    end

    it "prevents inviting a higher role than the creator (admin cannot invite owner)" do
      expect {
        described_class.create(team:, role: :owner, created_by: admin, expires_in: 1.day)
      }.to raise_error(Teams::InvitationService::RoleNotPermitted)
    end

    it "prevents members from creating invitations" do
      expect {
        described_class.create(team:, role: :viewer, created_by: member, expires_in: 1.day)
      }.to raise_error(Teams::InvitationService::RoleNotPermitted)
    end

    it "ensures uniqueness of token digests" do
      # Simulate many creations; should not raise and should return unique digests
      digests = 10.times.map {
        _inv, raw = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.day)
        described_class.digest(raw)
      }
      expect(digests.uniq.length).to eq(10)
    end
  end

  describe ".accept" do
    it "creates a membership and marks the invitation as used" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.day)

      expect {
        membership = described_class.accept(token: raw_token, user: invitee)
        expect(membership).to be_a(Membership)
        expect(membership.team).to eq(team)
        expect(membership.user).to eq(invitee)
        expect(membership.role).to eq("member")
      }.to change { team.memberships.count }.by(1)

      invitation.reload
      expect(invitation.used_at).to be_present
      expect(invitation.used_by).to eq(invitee)
    end

    it "raises when invitation is expired" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.hour)
      invitation.update!(expires_at: 1.hour.ago)

      expect {
        described_class.accept(token: raw_token, user: invitee)
      }.to raise_error(Invitation::InvitationExpired)
    end

    it "raises when invitation already used" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.day)
      described_class.accept(token: raw_token, user: invitee)

      expect {
        described_class.accept(token: raw_token, user: create(:user))
      }.to raise_error(Invitation::InvitationAlreadyUsed)
    end

    it "raises when user is already a member" do
      invitation, raw_token = described_class.create(team:, role: :member, created_by: owner, expires_in: 1.day)
      create(:membership, user: invitee, team:, role: :viewer)

      expect {
        described_class.accept(token: raw_token, user: invitee)
      }.to raise_error(Invitation::UserAlreadyMember)
    end
  end
end
