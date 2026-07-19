# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviewDetailSerializer do
  # Objetos leves com a mesma superfície que ComputeWeekService entrega ao
  # serializer (Data/Struct com os métodos lidos em #as_json).
  Totals = Struct.new(:worked_minutes, :standard_minutes, :overtime_minutes, :absences)
  Day = Struct.new(:date, :weekend, :worked_minutes, :overtime_minutes, :absence, :status, :intervals)

  let(:user) { build(:user) }

  # Dois intervalos no mesmo dia: um fechado e um ABERTO (end_at: nil) — este
  # exercita o lado nil do `interval[:end_at]&.strftime` no serializer.
  let(:day) do
    Day.new(
      Date.new(2026, 6, 1), false, 240, 0, false, "worked",
      [
        { start_at: Time.utc(2026, 6, 1, 8), end_at: Time.utc(2026, 6, 1, 12),
          start_location: nil, end_location: nil },
        { start_at: Time.utc(2026, 6, 1, 13), end_at: nil,
          start_location: nil, end_location: nil }
      ]
    )
  end

  let(:detail) do
    {
      user: user,
      week_start: Date.new(2026, 6, 1),
      week_end: Date.new(2026, 6, 7),
      expected_minutes: 2640,
      review: nil,
      totals: Totals.new(240, 240, 0, 0),
      days: [ day ]
    }
  end

  it "formats an open interval with a nil end time" do
    intervals = described_class.new(detail).as_json[:days].first[:intervals]

    expect(intervals.first[:end]).to eq("12:00")
    expect(intervals.last[:end]).to be_nil
    expect(intervals.last[:start]).to eq("13:00")
  end

  it "leaves review null while the week is pending" do
    expect(described_class.new(detail).as_json[:review]).to be_nil
  end
end
