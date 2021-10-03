# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TokenLimitService, :freeze_time do
  subject(:service) { described_class.call(profile: profile, quantity: quantity) }

  let(:team) { create(:team, tokens_disbursed_at: Time.current) }
  let(:profile) { create(:profile, team: team) }
  let(:quantity) { 2 }

  context 'when team.throttle_tips is true' do
    before do
      team.update(throttle_tips: true)
    end

    context 'when profile.infinite_tokens is true' do
      before { profile.infinite_tokens = true }

      it 'returns false' do
        expect(service).to eq(false)
      end
    end

    context 'when profile.accrued_tokens is sufficient' do
      before { profile.tokens_accrued = 2 }

      it 'returns false' do
        expect(service).to eq(false)
      end
    end

    context 'when profile.accrued_tokens is not sufficient' do
      let(:text) do
        <<~TEXT.chomp
          :#{App.error_emoji}: Giving #{points_format(2, label: true)} would exceed your token balance of 1. The next dispersal of #{team.token_quantity} tokens will occur in 1 day.
        TEXT
      end

      before do
        profile.tokens_accrued = 1
      end

      it 'returns false' do
        expect(service).to eq(text)
      end
    end
  end

  context 'when team.throttle_tips is false' do
    before do
      team.update(throttle_tips: false)
    end

    it 'returns false' do
      expect(service).to eq(false)
    end
  end
end
