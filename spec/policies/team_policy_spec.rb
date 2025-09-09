# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team) }
  let(:other_team) { create(:team) }

  describe '#index?' do
    context 'when user is logged in' do
      it 'allows access' do
        permit_action(:index, user: user, record: Team)
      end
    end

    context 'when user is not logged in' do
      it 'denies access' do
        forbid_action(:index, user: nil, record: Team)
      end
    end
  end

  describe '#show?' do
    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'allows access' do
        permit_action(:show, user: user, record: team, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies access' do
        forbid_action(:show, user: user, record: team, team: team)
      end
    end

    context 'when user is not logged in' do
      it 'denies access' do
        forbid_action(:show, user: nil, record: team, team: team)
      end
    end
  end

  describe '#create?' do
    context 'when user is logged in' do
      context 'when team creation is allowed' do
        before do
          allow(Rails.configuration).to receive(:respond_to?).and_return(true)
          allow(Rails.configuration).to receive(:allow_team_creation).and_return(true)
        end

        it 'allows team creation' do
          permit_action(:create, user: user, record: Team)
        end
      end

      context 'when team creation is disabled' do
        before do
          allow(Rails.configuration).to receive(:respond_to?).and_return(true)
          allow(Rails.configuration).to receive(:allow_team_creation).and_return(false)
        end

        it 'denies team creation' do
          forbid_action(:create, user: user, record: Team)
        end
      end

      context 'when configuration is not set' do
        before do
          allow(Rails.configuration).to receive(:respond_to?).and_return(false)
        end

        it 'defaults to allowing team creation' do
          permit_action(:create, user: user, record: Team)
        end
      end
    end

    context 'when user is not logged in' do
      it 'denies team creation' do
        forbid_action(:create, user: nil, record: Team)
      end
    end
  end

  describe '#update?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows updates' do
        permit_action(:update, user: user, record: team, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'allows updates' do
        permit_action(:update, user: user, record: team, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies updates' do
        forbid_action(:update, user: user, record: team, team: team)
      end
    end

    context 'when user is a team viewer' do
      before { create(:membership, user: user, team: team, role: 'viewer') }

      it 'denies updates' do
        forbid_action(:update, user: user, record: team, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies updates' do
        forbid_action(:update, user: user, record: team, team: team)
      end
    end
  end

  describe '#destroy?' do
    context 'when user is a team owner' do
      before { create(:membership, user: user, team: team, role: 'owner') }

      it 'allows deletion' do
        permit_action(:destroy, user: user, record: team, team: team)
      end
    end

    context 'when user is a team admin' do
      before { create(:membership, user: user, team: team, role: 'admin') }

      it 'denies deletion' do
        forbid_action(:destroy, user: user, record: team, team: team)
      end
    end

    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'denies deletion' do
        forbid_action(:destroy, user: user, record: team, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies deletion' do
        forbid_action(:destroy, user: user, record: team, team: team)
      end
    end
  end

  describe '#switch?' do
    context 'when user is a team member' do
      before { create(:membership, user: user, team: team, role: 'member') }

      it 'allows switching to this team' do
        permit_action(:switch, user: user, record: team, team: team)
      end
    end

    context 'when user is not a team member' do
      it 'denies switching to this team' do
        forbid_action(:switch, user: user, record: team, team: team)
      end
    end

    context 'when user is not logged in' do
      it 'denies switching' do
        forbid_action(:switch, user: nil, record: team, team: team)
      end
    end
  end

  describe 'Scope' do
    let(:user_team1) { create(:team) }
    let(:user_team2) { create(:team) }
    let(:other_user_team) { create(:team) }

    before do
      create(:membership, user: user, team: user_team1, role: 'member')
      create(:membership, user: user, team: user_team2, role: 'admin')
      create(:membership, user: other_user, team: other_user_team, role: 'owner')
    end

    context 'when user is logged in' do
      it 'returns only teams where user is a member' do
        resolved_scope = policy_scope(user, Team.all)

        expect(resolved_scope).to include(user_team1, user_team2)
        expect(resolved_scope).not_to include(other_user_team)
      end
    end

    context 'when user is not logged in' do
      it 'returns empty scope' do
        resolved_scope = policy_scope(nil, Team.all)

        expect(resolved_scope).to be_empty
      end
    end
  end
end
