# frozen_string_literal: true
class ChannelWorker
  include Sidekiq::Worker
  sidekiq_options queue: :channel_sync, lock: :until_executed

  def perform(team_rid, new_channel_rid = nil)
    team = Team.find_by!(rid: team_rid)
    return unless team.active?
    "#{team.plat}::ChannelService".constantize.call(team:, new_channel_rid:)
  end
end
