# frozen_string_literal: true

# Payload de GET /api/v1/users/:user_id/weekly_review: sempre 7 dias seg→dom,
# horários já formatados HH:MM no fuso de negócio (batem com os totais
# calculados no servidor); review é null enquanto a semana está pendente.
class WeeklyReviewDetailSerializer
  def initialize(detail)
    @detail = detail
  end

  def as_json
    totals = @detail[:totals]

    {
      user: UserSerializer.new(@detail[:user]).as_json,
      week_start: @detail[:week_start].iso8601,
      week_end: @detail[:week_end].iso8601,
      total_minutes: totals.worked_minutes,
      standard_minutes: totals.standard_minutes,
      overtime_minutes: totals.overtime_minutes,
      expected_minutes: @detail[:expected_minutes],
      absences: totals.absences,
      review: @detail[:review] && WeeklyReviewSerializer.new(@detail[:review]).as_json,
      days: @detail[:days].map { |day| day_json(day) }
    }
  end

  private

  def day_json(day)
    {
      date: day.date.iso8601,
      weekend: day.weekend,
      worked_minutes: day.worked_minutes,
      overtime_minutes: day.overtime_minutes,
      absence: day.absence,
      status: day.status,
      intervals: day.intervals.map do |interval|
        {
          start: interval[:start_at].strftime("%H:%M"),
          end: interval[:end_at]&.strftime("%H:%M"),
          start_location: location_json(interval[:start_location]),
          end_location: location_json(interval[:end_location])
        }
      end
    }
  end

  def location_json(point)
    return nil if point.nil?

    { latitude: point.y, longitude: point.x }
  end
end
