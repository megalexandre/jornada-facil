# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::UserDetailService do
  let(:week_start) { Date.new(2026, 6, 1) }
  let(:user) { create(:user) }

  def local(*args)
    WeeklyReviews.time_zone.local(*args)
  end

  it "returns the user's week with 7 days and totals" do
    create(:journey, user: user,
                     started_at: local(2026, 6, 1, 8, 0),
                     finished_at: local(2026, 6, 1, 18, 0))

    result = described_class.call(user_id: user.id, week_start: "2026-06-01")

    expect(result[:user]).to eq(user)
    expect(result[:week_start]).to eq(week_start)
    expect(result[:week_end]).to eq(Date.new(2026, 6, 7))
    expect(result[:expected_minutes]).to eq(2400)
    expect(result[:days].size).to eq(7)
    expect(result[:days].first.worked_minutes).to eq(600)
    expect(result[:totals].overtime_minutes).to eq(120)
    expect(result[:review]).to be_nil
  end

  it "includes the stored review when one exists" do
    review = create(:weekly_review, :rejected, user: user, week_start: week_start)

    result = described_class.call(user_id: user.id, week_start: "2026-06-01")

    expect(result[:review]).to eq(review)
  end

  it "ignores other users' journeys" do
    create(:journey, started_at: local(2026, 6, 1, 8, 0), finished_at: local(2026, 6, 1, 16, 0))

    result = described_class.call(user_id: user.id, week_start: "2026-06-01")

    expect(result[:totals].worked_minutes).to eq(0)
  end

  it "raises RecordNotFound for an unknown user" do
    expect { described_class.call(user_id: SecureRandom.uuid, week_start: "2026-06-01") }
      .to raise_error(RecordNotFound, "User not found")
  end
end
