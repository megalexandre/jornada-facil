# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::SummaryService do
  # Semana totalmente passada: seg 2026-06-01 a dom 2026-06-07.
  let(:week_start) { Date.new(2026, 6, 1) }

  def local(*args)
    WeeklyReviews.time_zone.local(*args)
  end

  def full_week_of_journeys(user, week_start)
    (0..4).each do |offset|
      date = week_start + offset
      create(:journey, user: user,
                       started_at: local(date.year, date.month, date.day, 8, 0),
                       finished_at: local(date.year, date.month, date.day, 16, 0))
    end
  end

  it "returns one row per user, ordered by name, with totals and status" do
    ana = create(:user, name: "Ana")
    bruno = create(:user, name: "Bruno")
    full_week_of_journeys(ana, week_start)

    result = described_class.call(week_start: "2026-06-01")

    expect(result[:week_start]).to eq(week_start)
    expect(result[:week_end]).to eq(Date.new(2026, 6, 7))
    expect(result[:rows].map { |row| row[:user] }).to eq([ ana, bruno ])

    ana_row, bruno_row = result[:rows]
    expect(ana_row[:worked_minutes]).to eq(2400)
    expect(ana_row[:expected_minutes]).to eq(2400)
    expect(ana_row[:status]).to eq("pending")
    expect(bruno_row[:worked_minutes]).to eq(0)
    expect(bruno_row[:absences]).to eq(5)
    expect(bruno_row[:status]).to eq("alert")
  end

  it "excludes users that don't track a journey (e.g. admins)" do
    ana = create(:user, name: "Ana")
    create(:user, :no_journey, name: "Zeca")

    result = described_class.call(week_start: "2026-06-01")

    expect(result[:rows].map { |row| row[:user] }).to eq([ ana ])
  end

  it "uses the stored review status when a review exists, even with anomalies" do
    ana = create(:user, name: "Ana")
    bruno = create(:user, name: "Bruno")
    create(:weekly_review, user: ana, week_start: week_start, reviewer: bruno)
    create(:weekly_review, :rejected, user: bruno, week_start: week_start, reviewer: ana)

    result = described_class.call(week_start: "2026-06-01")

    expect(result[:rows].map { |row| row[:status] }).to eq(%w[approved rejected])
  end

  it "computes the compliance rate as the share of users without anomalies" do
    ana = create(:user, name: "Ana")
    create(:user, name: "Bruno")
    full_week_of_journeys(ana, week_start)

    result = described_class.call(week_start: "2026-06-01")

    # Ana conforme, Bruno com 5 faltas → 1 de 2 = 50%.
    expect(result[:compliance_rate]).to eq(50)
  end

  it "computes the previous week's rate for the delta" do
    ana = create(:user, name: "Ana")
    full_week_of_journeys(ana, week_start - 7)

    result = described_class.call(week_start: "2026-06-01")

    expect(result[:previous_compliance_rate]).to eq(100)
    expect(result[:compliance_rate]).to eq(0)
  end

  it "snaps any date to the Monday of its week" do
    result = described_class.call(week_start: "2026-06-04")

    expect(result[:week_start]).to eq(week_start)
  end

  it "defaults to the current week" do
    result = described_class.call

    expect(result[:week_start])
      .to eq(WeeklyReviews.time_zone.today.beginning_of_week(:monday))
  end

  it "only counts journeys inside the requested week" do
    ana = create(:user, name: "Ana")
    create(:journey, user: ana,
                     started_at: local(2026, 5, 31, 8, 0),
                     finished_at: local(2026, 5, 31, 16, 0))
    create(:journey, user: ana,
                     started_at: local(2026, 6, 8, 8, 0),
                     finished_at: local(2026, 6, 8, 16, 0))

    result = described_class.call(week_start: "2026-06-01")

    expect(result[:rows].first[:worked_minutes]).to eq(0)
  end
end
