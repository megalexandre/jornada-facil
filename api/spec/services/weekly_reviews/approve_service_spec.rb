# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::ApproveService do
  let(:user) { create(:user) }
  let(:reviewer) { create(:user) }
  let(:week_start) { Date.new(2026, 6, 1) }

  it "creates an approved review for the user's week" do
    review = described_class.call(user_id: user.id, week_start: "2026-06-01", reviewer: reviewer)

    expect(review).to be_persisted
    expect(review).to be_approved
    expect(review.week_start).to eq(week_start)
    expect(review.reviewer).to eq(reviewer)
    expect(review.comment).to be_nil
  end

  it "snaps any date to the Monday of its week" do
    review = described_class.call(user_id: user.id, week_start: "2026-06-04", reviewer: reviewer)

    expect(review.week_start).to eq(week_start)
  end

  it "overwrites a previous rejection and clears its comment (upsert)" do
    existing = create(:weekly_review, :rejected, user: user, week_start: week_start)

    review = described_class.call(user_id: user.id, week_start: "2026-06-01", reviewer: reviewer)

    expect(review.id).to eq(existing.id)
    expect(review).to be_approved
    expect(review.comment).to be_nil
    expect(WeeklyReview.where(user_id: user.id, week_start: week_start).count).to eq(1)
  end

  it "notifies the employee with the week period" do
    allow(Notifications::SendPushService).to receive(:call)

    described_class.call(user_id: user.id, week_start: "2026-06-01", reviewer: reviewer)

    expect(Notifications::SendPushService).to have_received(:call).with(
      user: user,
      title: "Jornada semanal aprovada",
      body: "Sua jornada da semana de 01/06 a 07/06 foi aprovada."
    )
  end

  it "keeps the review when the push fails" do
    allow(Notifications::SendPushService).to receive(:call).and_raise(StandardError, "FCM down")

    review = described_class.call(user_id: user.id, week_start: "2026-06-01", reviewer: reviewer)

    expect(review).to be_persisted
    expect(review).to be_approved
  end
end
