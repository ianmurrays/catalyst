require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe "validations" do
    subject { build(:membership) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:team) }
    it { is_expected.to validate_presence_of(:role) }

    describe "unique user per team" do
      let(:user) { create(:user) }
      let(:team) { create(:team) }

      it "validates uniqueness of user_id scoped to team_id" do
        create(:membership, user: user, team: team)
        duplicate_membership = build(:membership, user: user, team: team)

        expect(duplicate_membership).not_to be_valid
        expect(duplicate_membership.errors[:user_id]).to include("has already been taken")
      end

      it "allows same user in different teams" do
        team2 = create(:team)
        create(:membership, user: user, team: team)
        membership2 = build(:membership, user: user, team: team2)

        expect(membership2).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:team) }
  end

  describe "role enum" do
    it "defines role enum correctly" do
      expect(Membership.roles).to eq({
        "owner" => 0,
        "admin" => 1,
        "member" => 2,
        "viewer" => 3
      })
    end

    it "allows setting roles by symbol" do
      membership = build(:membership, role: :admin)
      expect(membership.role).to eq("admin")
      expect(membership.admin?).to be true
    end

    it "allows setting roles by string" do
      membership = build(:membership, role: "owner")
      expect(membership.role).to eq("owner")
      expect(membership.owner?).to be true
    end

    it "defaults to member role" do
      membership = Membership.new
      expect(membership.role).to eq("member")
    end
  end

  describe "scopes" do
    let(:team) { create(:team) }
    let(:deleted_team) { create(:team, :deleted) }
    let!(:active_membership) { create(:membership, team: team) }
    let!(:deleted_team_membership) { create(:membership, team: deleted_team) }

    describe ".active" do
      it "returns memberships for non-deleted teams" do
        expect(Membership.active).to include(active_membership)
        expect(Membership.active).not_to include(deleted_team_membership)
      end
    end

    describe ".by_role" do
      let!(:owner_membership) { create(:membership, :owner, team: team) }
      let!(:admin_membership) { create(:membership, :admin, team: team) }
      let!(:member_membership) { create(:membership, :member, team: team) }

      it "filters by owner role" do
        expect(Membership.by_role(:owner)).to include(owner_membership)
        expect(Membership.by_role(:owner)).not_to include(admin_membership)
      end

      it "filters by admin role" do
        expect(Membership.by_role(:admin)).to include(admin_membership)
        expect(Membership.by_role(:admin)).not_to include(member_membership)
      end
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(Membership.audited_options[:on]).to include(:create, :update, :destroy)
    end

    it "audits role changes" do
      membership = create(:membership, :member)
      expect { membership.update!(role: :admin) }.to change { membership.audits.count }.by(1)
    end
  end

  describe "role checking methods" do
    let(:membership) { create(:membership, :admin) }

    it "provides role checking methods" do
      expect(membership).to respond_to(:owner?)
      expect(membership).to respond_to(:admin?)
      expect(membership).to respond_to(:member?)
      expect(membership).to respond_to(:viewer?)
    end

    it "returns correct boolean values" do
      expect(membership.admin?).to be true
      expect(membership.owner?).to be false
      expect(membership.member?).to be false
      expect(membership.viewer?).to be false
    end
  end

  describe "role hierarchy methods" do
    describe "#admin_or_above?" do
      it "returns true for owner" do
        membership = build(:membership, :owner)
        expect(membership.admin_or_above?).to be true
      end

      it "returns true for admin" do
        membership = build(:membership, :admin)
        expect(membership.admin_or_above?).to be true
      end

      it "returns false for member" do
        membership = build(:membership, :member)
        expect(membership.admin_or_above?).to be false
      end

      it "returns false for viewer" do
        membership = build(:membership, :viewer)
        expect(membership.admin_or_above?).to be false
      end
    end

    describe "#member_or_above?" do
      it "returns true for all roles except viewer" do
        expect(build(:membership, :owner).member_or_above?).to be true
        expect(build(:membership, :admin).member_or_above?).to be true
        expect(build(:membership, :member).member_or_above?).to be true
        expect(build(:membership, :viewer).member_or_above?).to be false
      end
    end
  end

  describe "delegation to user" do
    let(:user) { create(:user, display_name: "John Doe") }
    let(:membership) { create(:membership, user: user) }

    it "delegates user methods" do
      expect(membership.user_name).to eq("John Doe")
      expect(membership.user_email).to eq(user.email)
    end
  end
end
