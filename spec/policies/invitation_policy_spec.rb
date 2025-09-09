# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team) }
  let(:invitation) { create(:invitation, team: team, created_by: other_user, role: 'member') }

  describe '#index?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows viewing invitations' do
        permit_action(:index, user: user, record: Invitation, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows viewing invitations' do
        permit_action(:index, user: user, record: Invitation, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies viewing invitations' do
        forbid_action(:index, user: user, record: Invitation, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies viewing invitations' do
        forbid_action(:index, user: user, record: Invitation, team: team)
      end
    end

    context 'when user is not logged in' do
      it 'denies viewing invitations' do
        forbid_action(:index, user: nil, record: Invitation, team: team)
      end
    end
  end

  describe '#show?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows viewing invitation' do
        permit_action(:show, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows viewing invitation' do
        permit_action(:show, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies viewing invitation' do
        forbid_action(:show, user: user, record: invitation, team: team)
      end
    end
  end

  describe '#create?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows creating invitations' do
        permit_action(:create, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows creating invitations' do
        permit_action(:create, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies creating invitations' do
        forbid_action(:create, user: user, record: invitation, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies creating invitations' do
        forbid_action(:create, user: user, record: invitation, team: team)
      end
    end
  end

  describe '#update?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows updating invitations' do
        permit_action(:update, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows updating invitations' do
        permit_action(:update, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies updating invitations' do
        forbid_action(:update, user: user, record: invitation, team: team)
      end
    end
  end

  describe '#destroy?' do
    context 'when user is the invitation creator' do
      let(:user_invitation) { create(:invitation, team: team, created_by: user, role: 'member') }

      it 'allows deleting own invitation' do
        permit_action(:destroy, user: user, record: user_invitation, team: team)
      end
    end

    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows deleting any invitation' do
        permit_action(:destroy, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows deleting any invitation' do
        permit_action(:destroy, user: user, record: invitation, team: team)
      end
    end

    context 'when user is a team member but not the creator' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies deleting invitation' do
        forbid_action(:destroy, user: user, record: invitation, team: team)
      end
    end

    context 'when user is not a team member and not the creator' do
      it 'denies deleting invitation' do
        forbid_action(:destroy, user: user, record: invitation, team: team)
      end
    end
  end

  describe '#accept?' do
    let(:usable_invitation) { create(:invitation, team: team, created_by: other_user) }
    let(:expired_invitation) { create(:invitation, team: team, created_by: other_user, expires_at: 1.day.ago) }
    let(:used_invitation) { create(:invitation, team: team, created_by: other_user, used_at: 1.day.ago, used_by: other_user) }

    context 'when user is logged in' do
      context 'with a usable invitation' do
        before do
          allow(usable_invitation).to receive(:usable?).and_return(true)
        end

        it 'allows accepting invitation' do
          permit_action(:accept, user: user, record: usable_invitation, team: team)
        end
      end

      context 'with an expired invitation' do
        before do
          allow(expired_invitation).to receive(:usable?).and_return(false)
        end

        it 'denies accepting invitation' do
          forbid_action(:accept, user: user, record: expired_invitation, team: team)
        end
      end

      context 'with a used invitation' do
        before do
          allow(used_invitation).to receive(:usable?).and_return(false)
        end

        it 'denies accepting invitation' do
          forbid_action(:accept, user: user, record: used_invitation, team: team)
        end
      end
    end

    context 'when user is not logged in' do
      it 'denies accepting invitation' do
        forbid_action(:accept, user: nil, record: usable_invitation, team: team)
      end
    end
  end

  describe 'Scope' do
    let(:user_team) { create(:team) }
    let(:other_team) { create(:team) }
    let(:user_invitation) { create(:invitation, team: user_team, created_by: user) }
    let(:team_invitation) { create(:invitation, team: user_team, created_by: other_user) }
    let(:other_team_invitation) { create(:invitation, team: other_team, created_by: other_user) }

    before do
      user_invitation
      team_invitation
      other_team_invitation
    end

    context 'when user is logged in with team admin privileges' do
      before { create(:membership, user: user, team: user_team, role: 'admin') }

      it 'returns invitations for teams where user has admin privileges' do
        resolved_scope = policy_scope(user, Invitation.all, user_team)

        expect(resolved_scope).to include(user_invitation, team_invitation)
        expect(resolved_scope).not_to include(other_team_invitation)
      end
    end

    context 'when user is logged in with no team context' do
      it 'returns invitations created by user' do
        resolved_scope = policy_scope(user, Invitation.all, nil)

        expect(resolved_scope).to include(user_invitation)
        expect(resolved_scope).not_to include(team_invitation, other_team_invitation)
      end
    end

    context 'when user is not logged in' do
      it 'returns empty scope' do
        resolved_scope = policy_scope(nil, Invitation.all)

        expect(resolved_scope).to be_empty
      end
    end
  end
end
