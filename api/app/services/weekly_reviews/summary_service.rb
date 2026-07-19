# frozen_string_literal: true

module WeeklyReviews
  # Visão do admin sobre a semana: todos os usuários com totais, status da
  # revisão e a taxa de conformidade (atual e da semana anterior, para o delta).
  # Conformidade independe de revisão: usuário sem hora extra e sem falta.
  class SummaryService
    def self.call(week_start: nil)
      new(week_start:).call
    end

    def initialize(week_start:)
      @week_start = WeeklyReviews.normalize_week_start(week_start)
    end

    def call
      rows = build_rows(@week_start)

      {
        week_start: @week_start,
        week_end: @week_start + 6,
        compliance_rate: compliance_rate(rows),
        previous_compliance_rate: compliance_rate(build_rows(@week_start - 7)),
        rows: rows
      }
    end

    private

    def build_rows(week_start)
      journeys = journeys_by_user(week_start)
      reviews = WeeklyReview.where(week_start: week_start).index_by(&:user_id)

      User.journey_trackers.order(:name).map do |user|
        review = reviews[user.id]
        computed = ComputeWeekService.call(
          journeys: journeys.fetch(user.id, []),
          week_start: week_start,
          review: review
        )

        {
          user: user,
          status: row_status(review, computed.totals),
          worked_minutes: computed.totals.worked_minutes,
          expected_minutes: EXPECTED_WEEK_MINUTES,
          overtime_minutes: computed.totals.overtime_minutes,
          absences: computed.totals.absences
        }
      end
    end

    def journeys_by_user(week_start)
      from = WeeklyReviews.time_zone.local(week_start.year, week_start.month, week_start.day)
      Journey
        .where(started_at: from...(from + 7.days))
        .group_by(&:user_id)
    end

    def row_status(review, totals)
      return review.status if review

      anomalous = totals.overtime_minutes.positive? || totals.absences.positive?
      anomalous ? "alert" : "pending"
    end

    def compliance_rate(rows)
      return 100 if rows.empty?

      compliant = rows.count do |row|
        row[:overtime_minutes].zero? && row[:absences].zero?
      end
      (100.0 * compliant / rows.size).round
    end
  end
end
