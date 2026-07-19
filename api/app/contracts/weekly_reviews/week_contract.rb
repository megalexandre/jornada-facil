# frozen_string_literal: true

module WeeklyReviews
  # week_start é opcional (default: semana atual); quando presente precisa ser
  # uma data real em YYYY-MM-DD — qualquer dia da semana serve, o serviço faz
  # o snap para a segunda-feira.
  class WeekContract < ApplicationContract
    attribute :week_start, :string

    validate :week_start_must_be_a_date

    private

    def week_start_must_be_a_date
      return if week_start.blank?

      Date.iso8601(week_start)
    rescue Date::Error
      errors.add(:week_start, "must be a valid date (YYYY-MM-DD)")
    end
  end
end
