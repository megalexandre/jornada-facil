# frozen_string_literal: true

module WeeklyReviews
  # Matemática pura de uma semana: recebe as jornadas do usuário na janela e
  # devolve os 7 dias (seg→dom) com minutos trabalhados, hora extra, falta,
  # status e intervalos, mais os totais da semana.
  #
  # Regras:
  # - A jornada conta inteira no dia local (fuso de negócio) do started_at,
  #   mesmo atravessando a meia-noite.
  # - Jornada aberta contribui até min(agora, fim da semana).
  # - Dia útil: acima de DAILY_MINUTES vira hora extra. Fim de semana: tudo
  #   é hora extra.
  # - Falta: dia útil sem jornada que já passou (hoje e futuro não contam).
  class ComputeWeekService
    Day = Struct.new(
      :date, :weekend, :worked_minutes, :overtime_minutes, :absence, :status, :intervals,
      keyword_init: true
    )
    Totals = Struct.new(
      :worked_minutes, :standard_minutes, :overtime_minutes, :absences,
      keyword_init: true
    )
    Result = Struct.new(:days, :totals, keyword_init: true)

    def self.call(journeys:, week_start:, review: nil, now: Time.current)
      new(journeys:, week_start:, review:, now:).call
    end

    def initialize(journeys:, week_start:, review:, now:)
      @journeys = journeys
      @week_start = week_start
      @review = review
      @now = now
    end

    def call
      days = (0..6).map { |offset| build_day(@week_start + offset) }

      Result.new(
        days: days,
        totals: Totals.new(
          worked_minutes: days.sum(&:worked_minutes),
          standard_minutes: days.sum { |day| day.weekend ? 0 : day.worked_minutes - day.overtime_minutes },
          overtime_minutes: days.sum(&:overtime_minutes),
          absences: days.count(&:absence)
        )
      )
    end

    private

    def build_day(date)
      journeys = journeys_by_date.fetch(date, [])
      weekend = date.saturday? || date.sunday?
      worked = journeys.sum { |journey| worked_minutes(journey) }
      overtime = weekend ? worked : [ worked - DAILY_MINUTES, 0 ].max
      absence = !weekend && journeys.empty? && past_day?(date)

      Day.new(
        date: date,
        weekend: weekend,
        worked_minutes: worked,
        overtime_minutes: overtime,
        absence: absence,
        status: day_status(weekend:, worked:, overtime:, absence:),
        intervals: journeys.map { |journey| interval(journey) }
      )
    end

    def day_status(weekend:, worked:, overtime:, absence:)
      if weekend
        overtime.positive? ? "overtime" : "rest"
      elsif absence
        "absence"
      elsif overtime.positive?
        "overtime"
      elsif @review&.approved?
        "approved"
      else
        "pending"
      end
    end

    def journeys_by_date
      @journeys_by_date ||= @journeys
        .sort_by(&:started_at)
        .group_by { |journey| journey.started_at.in_time_zone(WeeklyReviews.time_zone).to_date }
    end

    def worked_minutes(journey)
      finish = journey.finished_at || [ @now, week_end_time ].min
      ((finish - journey.started_at) / 60).floor.clamp(0..)
    end

    def interval(journey)
      {
        start_at: journey.started_at.in_time_zone(WeeklyReviews.time_zone),
        end_at: journey.finished_at&.in_time_zone(WeeklyReviews.time_zone),
        start_location: journey.started_location,
        end_location: journey.finished_location
      }
    end

    def past_day?(date)
      date < @now.in_time_zone(WeeklyReviews.time_zone).to_date
    end

    def week_end_time
      @week_end_time ||= begin
        date = @week_start + 7
        WeeklyReviews.time_zone.local(date.year, date.month, date.day)
      end
    end
  end
end
