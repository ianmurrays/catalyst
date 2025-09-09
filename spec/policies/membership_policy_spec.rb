# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembershipPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team) }
  let(:membership) { create(:membership, user: other_user, team: team, role: 'member') }

  describe '#index?' do
    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'allows viewing member list' do
        permit_action(:index, user: user, record: Membership, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies viewing member list' do
        forbid_action(:index, user: user, record: Membership, team: team)
      end
    end

    context 'when user is not logged in' do
      it 'denies viewing member list' do
        forbid_action(:index, user: nil, record: Membership, team: team)
      end
    end
  end

  describe '#show?' do
    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'allows viewing membership' do
        permit_action(:show, user: user, record: membership, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies viewing membership' do
        forbid_action(:show, user: user, record: membership, team: team)
      end
    end
  end

  describe '#create?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows creating memberships' do
        permit_action(:create, user: user, record: membership, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows creating memberships' do
        permit_action(:create, user: user, record: membership, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies creating memberships' do
        forbid_action(:create, user: user, record: membership, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies creating memberships' do
        forbid_action(:create, user: user, record: membership, team: team)
      end
    end
  end

  describe '#update?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      context 'with regular role change' do
        it 'allows updating membership' do
          permit_action(:update, user: user, record: membership, team: team)
        end
      end

      context 'when demoting the last owner' do
        let(:owner_team) { create(:team) }
        let!(:user_membership) { create(:membership, user: user, team: owner_team, role: 'owner') }
        let!(:last_owner_membership) { create(:membership, user: other_user, team: owner_team, role: 'owner') }

        before do
          # Remove the user's membership so other_user becomes the last owner
          user_membership.destroy!

          # Simulate changing the role from owner to admin
          allow(last_owner_membership).to receive(:role_changed?).and_return(true)
          allow(last_owner_membership).to receive(:persisted?).and_return(true)
          allow(last_owner_membership).to receive(:role_was).and_return('owner')
          allow(last_owner_membership).to receive(:role).and_return('admin')

          # Create a new admin membership for user so they can perform the update
          create(:membership, user: user, team: owner_team, role: 'admin')
        end

        it 'denies updating membership' do
          forbid_action(:update, user: user, record: last_owner_membership, team: owner_team)
        end
      end

      context 'when user tries to demote themselves from owner' do
        let(:owner_team) { create(:team) }
        let!(:self_membership) { create(:membership, user: user, team: owner_team, role: 'owner') }

        before do
          # Simulate changing the role from owner to admin
          allow(self_membership).to receive(:role_changed?).and_return(true)
          allow(self_membership).to receive(:persisted?).and_return(true)
          allow(self_membership).to receive(:role_was).and_return('owner')
          allow(self_membership).to receive(:role).and_return('admin')
        end

        it 'denies self-demotion from owner' do
          forbid_action(:update, user: user, record: self_membership, team: owner_team)
        end
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows updating membership' do
        permit_action(:update, user: user, record: membership, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies updating membership' do
        forbid_action(:update, user: user, record: membership, team: team)
      end
    end
  end

  describe '#destroy?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      context 'removing a regular member' do
        it 'allows removing membership' do
          permit_action(:destroy, user: user, record: membership, team: team)
        end
      end

      context 'when removing the last owner' do
        let(:destroy_team) { create(:team) }
        let!(:user_owner_membership) { create(:membership, user: user, team: destroy_team, role: 'owner') }
        let!(:last_owner_membership) { create(:membership, user: other_user, team: destroy_team, role: 'owner') }

        before do
          # Remove the user's ownership so other_user becomes the last owner
          user_owner_membership.destroy!

          # Create a new admin membership for user so they can perform the destroy
          create(:membership, user: user, team: destroy_team, role: 'admin')
        end

        it 'denies removing the last owner' do
          forbid_action(:destroy, user: user, record: last_owner_membership, team: destroy_team)
        end
      end

      context 'when removing themselves as the last owner' do
        let(:self_destroy_team) { create(:team) }
        let!(:self_membership) { create(:membership, user: user, team: self_destroy_team, role: 'owner') }

        it 'denies self-removal as last owner' do
          # This test doesn't need any special setup since user is already the only owner
          forbid_action(:destroy, user: user, record: self_membership, team: self_destroy_team)
        end
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows removing membership' do
        permit_action(:destroy, user: user, record: membership, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies removing membership' do
        forbid_action(:destroy, user: user, record: membership, team: team)
      end
    end
  end

  describe 'Scope' do
    let(:user_team) { create(:team) }
    let(:other_team) { create(:team) }
    let(:user_membership) { create(:membership, user: user, team: user_team, role: 'admin') }
    let(:other_user_membership) { create(:membership, user: other_user, team: user_team, role: 'member') }
    let(:different_team_membership) { create(:membership, user: other_user, team: other_team, role: 'owner') }

    before do
      user_membership
      other_user_membership
      different_team_membership
    end

    context 'when user is logged in' do
      it 'returns memberships for teams where user is a member' do
        resolved_scope = policy_scope(user, Membership.all, user_team)

        expect(resolved_scope).to include(user_membership, other_user_membership)
        expect(resolved_scope).not_to include(different_team_membership)
      end
    end

    context 'when user is not logged in' do
      it 'returns empty scope' do
        resolved_scope = policy_scope(nil, Membership.all)

        expect(resolved_scope).to be_empty
      end
    end

    context 'when no team context' do
      it 'returns memberships for all teams where user is a member' do
        # Create another team membership
        another_team = create(:team)
        another_membership = create(:membership, user: user, team: another_team, role: 'member')

        resolved_scope = policy_scope(user, Membership.all, nil)

        expect(resolved_scope).to include(user_membership, another_membership)
        expect(resolved_scope).not_to include(different_team_membership)
      end
    end
  end
end
