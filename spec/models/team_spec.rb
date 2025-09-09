require 'rails_helper'

RSpec.describe Team, type: :model do
  describe "validations" do
    subject { build(:team) }

    it { is_expected.to validate_presence_of(:name) }

    context "slug uniqueness" do
      it "validates uniqueness of slug among non-deleted teams" do
        create(:team, slug: "existing-team")
        team = build(:team, slug: "existing-team")
        expect(team).not_to be_valid
        expect(team.errors[:slug]).to include("is already taken")
      end

      it "allows same slug for deleted team" do
        create(:team, :deleted, slug: "deleted-team")
        team = build(:team, slug: "deleted-team")
        expect(team).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:memberships) }
    it { is_expected.to have_many(:invitations).dependent(:destroy) }
    it { is_expected.to have_many(:owners).through(:memberships) }
    it { is_expected.to have_many(:admins).through(:memberships) }
    it { is_expected.to have_many(:members).through(:memberships) }
  end

  describe "scopes" do
    let!(:active_team) { create(:team) }
    let!(:deleted_team) { create(:team, :deleted) }

    describe ".active" do
      it "returns only non-deleted teams" do
        expect(Team.active).to include(active_team)
        expect(Team.active).not_to include(deleted_team)
      end
    end

    describe ".deleted" do
      it "returns only deleted teams" do
        expect(Team.deleted).to include(deleted_team)
        expect(Team.deleted).not_to include(active_team)
      end
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(Team.audited_options[:on]).to include(:create, :update, :destroy)
    end
  end

  describe "slug generation" do
    context "when name is provided" do
      it "generates slug from name" do
        team = build(:team, name: "My Awesome Team", slug: nil)
        team.valid?
        expect(team.slug).to eq("my-awesome-team")
      end

      it "handles special characters in name" do
        team = build(:team, name: "Team with Special Characters!@#", slug: nil)
        team.valid?
        expect(team.slug).to eq("team-with-special-characters")
      end

      it "ensures slug uniqueness by adding number suffix" do
        create(:team, slug: "duplicate-team")
        team = build(:team, name: "Duplicate Team", slug: nil)
        team.valid?
        expect(team.slug).to eq("duplicate-team-1")
      end
    end
  end

  describe "soft deletion" do
    let(:team) { create(:team) }

    describe "#destroy" do
      it "soft deletes the team by setting deleted_at" do
        expect { team.destroy }.to change { team.reload.deleted_at }.from(nil)
      end

      it "does not actually remove the record" do
        team.destroy
        expect(Team.unscoped.find(team.id)).to eq(team)
      end
    end

    describe "#deleted?" do
      it "returns false for active team" do
        expect(team.deleted?).to be false
      end

      it "returns true for deleted team" do
        team.update(deleted_at: 1.day.ago)
        expect(team.deleted?).to be true
      end
    end

    describe "#restore" do
      it "restores a soft-deleted team" do
        team.destroy
        team.restore
        expect(team.deleted?).to be false
        expect(team.deleted_at).to be_nil
      end
    end
  end

  describe "member checking methods" do
    let(:team) { create(:team) }
    let(:user) { create(:user) }

    describe "#has_member?" do
      context "when user is a member" do
        before { create(:membership, :member, user: user, team: team) }

        it "returns true" do
          expect(team.has_member?(user)).to be true
        end
      end

      context "when user is not a member" do
        it "returns false" do
          expect(team.has_member?(user)).to be false
        end
      end
    end

    describe "#member_role" do
      context "when user is a member" do
        before { create(:membership, :admin, user: user, team: team) }

        it "returns the user's role" do
          expect(team.member_role(user)).to eq("admin")
        end
      end

      context "when user is not a member" do
        it "returns nil" do
          expect(team.member_role(user)).to be_nil
        end
      end
    end

    describe "#owner?" do
      context "when user is an owner" do
        before { create(:membership, :owner, user: user, team: team) }

        it "returns true" do
          expect(team.owner?(user)).to be true
        end
      end

      context "when user is not an owner" do
        before { create(:membership, :member, user: user, team: team) }

        it "returns false" do
          expect(team.owner?(user)).to be false
        end
      end
    end

    describe "#admin?" do
      context "when user is an admin" do
        before { create(:membership, :admin, user: user, team: team) }

        it "returns true" do
          expect(team.admin?(user)).to be true
        end
      end

      context "when user is an owner" do
        before { create(:membership, :owner, user: user, team: team) }

        it "returns true (owners have admin privileges)" do
          expect(team.admin?(user)).to be true
        end
      end

      context "when user is only a member" do
        before { create(:membership, :member, user: user, team: team) }

        it "returns false" do
          expect(team.admin?(user)).to be false
        end
      end
    end
  end

  describe "#to_param" do
    let(:team) { create(:team, slug: "my-team") }

    it "returns the slug" do
      expect(team.to_param).to eq("my-team")
    end
  end
end
