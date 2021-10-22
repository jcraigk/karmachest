# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Actions::ReactionAdded do
  subject(:action) { described_class.call(params) }

  let(:team) { create(:team) }
  let(:sender) { create(:profile, team: team) }
  let(:recipient) { create(:profile, team: team) }
  let(:channel) { create(:channel, team: team) }
  let(:ts) { Time.current.to_f.to_s }
  let(:curated_params) do
    {
      channel_rid: channel.rid,
      message_ts: ts,
      profile_rid: sender.rid,
      team_rid: team.rid,
      event_ts: ts
    }
  end
  let(:slack_params) do
    {
      event: {
        reaction: reaction,
        item: {
          ts: ts,
          channel: channel.rid
        },
        item_user: recipient.rid
      }
    }
  end
  let(:params) { curated_params.merge(slack_params) }

  before { allow(TipMentionService).to receive(:call) }

  shared_examples 'exits' do
    it 'does not call TipMentionService' do
      action
      expect(TipMentionService).not_to have_received(:call)
    end
  end

  context 'when reaction is kudos emoji' do
    let(:reaction) { team.tip_emoji }
    let(:expected_args) do
      {
        profile: sender,
        mentions: [
          OpenStruct.new(
            rid: "#{PROF_PREFIX}#{recipient.rid}",
            quantity: team.emoji_quantity,
            topic_id: nil
          )
        ],
        source: 'reaction',
        event_ts: "#{ts}-reaction-#{sender.id}",
        channel_rid: channel.rid,
        channel_name: channel.name
      }
    end

    it 'calls TipMentionService' do
      action
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end

    context 'when team.enable_emoji is false' do
      before { team.update(enable_emoji: false) }

      include_examples 'exits'
    end
  end

  context 'when ditto reaction to message associated with tips' do
    let(:reaction) { team.ditto_emoji }
    let(:recipient2) { create(:profile, team: team) }
    let(:expected_args) do
      {
        profile: sender,
        mentions: [
          OpenStruct.new(
            rid: "#{PROF_PREFIX}#{recipient.rid}",
            quantity: quantity,
            topic_id: nil
          ),
          OpenStruct.new(
            rid: "#{PROF_PREFIX}#{recipient2.rid}",
            quantity: quantity,
            topic_id: nil
          )
        ],
        source: 'ditto',
        event_ts: "#{ts}-ditto-#{sender.id}",
        channel_rid: channel.rid,
        channel_name: channel.name
      }
    end
    let(:quantity) { 2 }

    # Testing both variations here - the original gift message
    # and the response. Normally these would not be associated
    # with the same event_ts, but it's irrelevant for the test
    before do
      create(
        :tip,
        from_profile: sender,
        to_profile: recipient,
        quantity: quantity,
        event_ts: ts
      )
      create(
        :tip,
        from_profile: sender,
        to_profile: recipient2,
        quantity: quantity,
        response_ts: ts
      )
      # This should be ignored as to_profile is sender (cannot give to self)
      create(
        :tip,
        from_profile: recipient2,
        to_profile: sender,
        quantity: quantity,
        response_ts: ts
      )
      action
    end

    it 'calls TipMentionService' do
      expect(TipMentionService).to have_received(:call).with(expected_args)
    end
  end

  xcontext 'when reaction is topic emoji' do
  end

  context 'when reaction is not correct emoji' do
    let(:reaction) { 'invalid_emoji' }

    include_examples 'exits'
  end

  context 'when discord' do
    let(:reaction) { App.default_tip_emoji }
    let(:params) { curated_params.merge(emoji: App.default_tip_emoji) }

    before do
      team.update(platform: :discord)
      action
    end

    it 'calls TipMentionService' do
      expect(TipMentionService).to have_received(:call)
    end
  end
end
