# frozen_string_literal: true
class Base::Service
  extend Dry::Initializer
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TranslationHelper
  include PointsHelper

  def self.call(...)
    new(...).call
  end

  private

  def floor_increment(value, increment)
    mult = 1 / increment.to_f
    (value * mult).floor / mult
  end
end
