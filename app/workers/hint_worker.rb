# frozen_string_literal: true
class HintWorker
  include Sidekiq::Worker
  sidekiq_options queue: :hourly, lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    return unless team.active? && !team.hint_frequency.never?
    HintService.call(team: team)
  end
end
