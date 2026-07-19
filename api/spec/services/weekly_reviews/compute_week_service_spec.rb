# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::ComputeWeekService do
  # Semana fixa e totalmente passada: seg 2026-06-01 a dom 2026-06-07.
  # America/Sao_Paulo = UTC-3 (sem horário de verão desde 2019).
  let(:week_start) { Date.new(2026, 6, 1) }
  let(:now) { local(2026, 6, 30, 12, 0) }
  let(:user) { build(:user) }

  def local(*args)
    WeeklyReviews.time_zone.local(*args)
  end

  def journey(started_at, finished_at = nil)
    build(:journey, user: user, started_at: started_at, finished_at: finished_at)
  end

  def compute(journeys, review: nil, at: now)
    described_class.call(journeys: journeys, week_start: week_start, review: review, now: at)
  end

  describe "hours per day" do
    it "computes a standard 8h weekday with no overtime and ordered intervals" do
      result = compute([
        journey(local(2026, 6, 1, 13, 0), local(2026, 6, 1, 17, 0)),
        journey(local(2026, 6, 1, 8, 0), local(2026, 6, 1, 12, 0))
      ])

      monday = result.days.first
      expect(monday.worked_minutes).to eq(480)
      expect(monday.overtime_minutes).to eq(0)
      expect(monday.status).to eq("pending")
      expect(monday.intervals.map { |i| i[:start_at].strftime("%H:%M") }).to eq([ "08:00", "13:00" ])
    end

    it "counts minutes beyond 8h on a weekday as overtime" do
      result = compute([ journey(local(2026, 6, 2, 7, 30), local(2026, 6, 2, 17, 30)) ])

      tuesday = result.days[1]
      expect(tuesday.worked_minutes).to eq(600)
      expect(tuesday.overtime_minutes).to eq(120)
      expect(tuesday.status).to eq("overtime")
    end

    it "counts all weekend work as overtime" do
      result = compute([ journey(local(2026, 6, 6, 9, 0), local(2026, 6, 6, 12, 0)) ])

      saturday = result.days[5]
      expect(saturday.weekend).to be true
      expect(saturday.worked_minutes).to eq(180)
      expect(saturday.overtime_minutes).to eq(180)
      expect(saturday.status).to eq("overtime")
    end
  end

  describe "day attribution" do
    it "attributes a midnight-spanning journey entirely to the day it started" do
      result = compute([ journey(local(2026, 6, 5, 22, 0), local(2026, 6, 6, 2, 0)) ])

      friday = result.days[4]
      saturday = result.days[5]
      expect(friday.worked_minutes).to eq(240)
      expect(saturday.worked_minutes).to eq(0)
    end

    it "buckets by the business timezone, not UTC" do
      # 2026-06-02 01:00 UTC = seg 2026-06-01 22:00 em São Paulo.
      result = compute([ journey(Time.utc(2026, 6, 2, 1, 0), Time.utc(2026, 6, 2, 2, 0)) ])

      expect(result.days.first.worked_minutes).to eq(60)
      expect(result.days[1].worked_minutes).to eq(0)
    end
  end

  describe "open journeys" do
    it "counts an open journey up to now" do
      at = local(2026, 6, 3, 12, 0)
      result = compute([ journey(local(2026, 6, 3, 10, 0)) ], at: at)

      wednesday = result.days[2]
      expect(wednesday.worked_minutes).to eq(120)
      expect(wednesday.intervals.first[:end_at]).to be_nil
    end

    it "caps a stale open journey at the end of the week" do
      result = compute([ journey(local(2026, 6, 5, 22, 0)) ])

      # sex 22:00 até o fim da semana (seg 00:00) = 50h = 3000min.
      expect(result.days[4].worked_minutes).to eq(3000)
    end
  end

  describe "absences" do
    it "marks a past weekday without journeys as absence" do
      result = compute([])

      expect(result.days.first.absence).to be true
      expect(result.days.first.status).to eq("absence")
      expect(result.totals.absences).to eq(5)
    end

    it "does not mark weekends as absence" do
      result = compute([])

      expect(result.days[5].absence).to be false
      expect(result.days[5].status).to eq("rest")
      expect(result.days[6].absence).to be false
    end

    it "does not mark today or future days as absence" do
      at = local(2026, 6, 3, 9, 0)
      result = compute([], at: at)

      expect(result.days[1].absence).to be true   # terça, passada
      expect(result.days[2].absence).to be false  # quarta, hoje
      expect(result.days[3].absence).to be false  # quinta, futuro
      expect(result.totals.absences).to eq(2)
    end
  end

  describe "approved review" do
    it "marks normal weekdays as approved when the week's review is approved" do
      review = build(:weekly_review, week_start: week_start)
      result = compute(
        [ journey(local(2026, 6, 1, 8, 0), local(2026, 6, 1, 16, 0)) ],
        review: review
      )

      expect(result.days.first.status).to eq("approved")
      # Falta e hora extra continuam visíveis mesmo com a semana aprovada.
      expect(result.days[1].status).to eq("absence")
    end
  end

  describe "totals" do
    it "sums worked, standard, overtime and absences across the week" do
      result = compute([
        journey(local(2026, 6, 1, 8, 0), local(2026, 6, 1, 18, 0)),  # 10h → 2h extra
        journey(local(2026, 6, 2, 8, 0), local(2026, 6, 2, 16, 0)),  # 8h
        journey(local(2026, 6, 6, 9, 0), local(2026, 6, 6, 11, 0))   # sábado 2h extra
      ])

      expect(result.totals.worked_minutes).to eq(1200)
      expect(result.totals.standard_minutes).to eq(960)
      expect(result.totals.overtime_minutes).to eq(240)
      expect(result.totals.absences).to eq(3)
    end
  end
end
