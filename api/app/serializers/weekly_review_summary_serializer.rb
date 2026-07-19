# frozen_string_literal: true

# Payload de GET /api/v1/weekly_reviews: a semana, as taxas de conformidade e
# uma linha por usuário. Minutos são inteiros; o app formata "48h30 / 40h".
class WeeklyReviewSummarySerializer
  def initialize(summary)
    @summary = summary
  end

  def as_json
    {
      week_start: @summary[:week_start].iso8601,
      week_end: @summary[:week_end].iso8601,
      compliance_rate: @summary[:compliance_rate],
      previous_compliance_rate: @summary[:previous_compliance_rate],
      users: @summary[:rows].map { |row| row_json(row) }
    }
  end

  private

  def row_json(row)
    {
      id: row[:user].id,
      name: row[:user].name,
      status: row[:status],
      worked_minutes: row[:worked_minutes],
      expected_minutes: row[:expected_minutes],
      overtime_minutes: row[:overtime_minutes],
      absences: row[:absences]
    }
  end
end
