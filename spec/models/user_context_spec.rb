# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserContext, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:user_context) { UserContext.new(user, team) }

  describe '#team_role' do
    context 'when user and team are present' do
      context 'when user is a member of the team' do
        let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

        it 'returns the user role in the team' do
          expect(user_context.team_role).to eq('admin')
        end
      end

      context 'when user is not a member of the team' do
        it 'returns nil' do
          expect(user_context.team_role).to be_nil
        end
      end
    end

    context 'when user is nil' do
      let(:user_context) { UserContext.new(nil, team) }

      it 'returns nil' do
        expect(user_context.team_role).to be_nil
      end
    end

    context 'when team is nil' do
      let(:user_context) { UserContext.new(user, nil) }

      it 'returns nil' do
        expect(user_context.team_role).to be_nil
      end
    end
  end

  describe '#team_member?' do
    context 'when user has a role in the team' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'member') }

      it 'returns true' do
        expect(user_context.team_member?).to be true
      end
    end

    context 'when user has no role in the team' do
      it 'returns false' do
        expect(user_context.team_member?).to be false
      end
    end
  end

  describe '#team_owner?' do
    context 'when user is an owner' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'owner') }

      it 'returns true' do
        expect(user_context.team_owner?).to be true
      end
    end

    context 'when user is not an owner' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

      it 'returns false' do
        expect(user_context.team_owner?).to be false
      end
    end
  end

  describe '#team_admin?' do
    context 'when user is an admin' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

      it 'returns true' do
        expect(user_context.team_admin?).to be true
      end
    end

    context 'when user is not an admin' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'member') }

      it 'returns false' do
        expect(user_context.team_admin?).to be false
      end
    end
  end

  describe '#team_admin_or_owner?' do
    context 'when user is an owner' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'owner') }

      it 'returns true' do
        expect(user_context.team_admin_or_owner?).to be true
      end
    end

    context 'when user is an admin' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'admin') }

      it 'returns true' do
        expect(user_context.team_admin_or_owner?).to be true
      end
    end

    context 'when user is a member' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'member') }

      it 'returns false' do
        expect(user_context.team_admin_or_owner?).to be false
      end
    end

    context 'when user is a viewer' do
      let!(:membership) { create(:membership, user: user, team: team, role: 'viewer') }

      it 'returns false' do
        expect(user_context.team_admin_or_owner?).to be false
      end
    end
  end
end
