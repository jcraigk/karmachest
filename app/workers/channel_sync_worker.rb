# frozen_string_literal: true
class ChannelSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :channel_sync, lock: :until_executed

  def perform(team_rid, new_channel_rid = nil)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::ChannelSyncService".constantize.call(team:, new_channel_rid:)
  end
end
