# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::TeamJoin do
  subject(:action) { described_class.call(**params) }

  let(:team) { create(:team) }
  let(:params) { { team_rid: team.rid } }

  before do
    allow(TeamSyncWorker).to receive(:perform_async)
  end

  it 'calls TeamSyncWorker' do
    action
    expect(TeamSyncWorker).to have_received(:perform_async).with(team.rid)
  end

  it 'responds silently' do
    expect(action).to eq(nil)
  end
end
