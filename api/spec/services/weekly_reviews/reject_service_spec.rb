# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReviews::RejectService do
  let(:user) { create(:user) }
  let(:reviewer) { create(:user) }
  let(:week_start) { Date.new(2026, 6, 1) }

  it "creates a rejected review with the comment" do
    review = described_class.call(
      user_id: user.id, week_start: "2026-06-01", comment: "Faltas sem justificativa", reviewer: reviewer
    )

    expect(review).to be_persisted
    expect(review).to be_rejected
    expect(review.week_start).to eq(week_start)
    expect(review.comment).to eq("Faltas sem justificativa")
    expect(review.reviewer).to eq(reviewer)
  end

  it "overwrites a previous approval (upsert)" do
    existing = create(:weekly_review, user: user, week_start: week_start)

    review = described_class.call(
      user_id: user.id, week_start: "2026-06-01", comment: "Rever horas extras", reviewer: reviewer
    )

    expect(review.id).to eq(existing.id)
    expect(review).to be_rejected
    expect(review.comment).to eq("Rever horas extras")
  end

  it "notifies the employee with the period and the reason" do
    allow(Notifications::SendPushService).to receive(:call)

    described_class.call(
      user_id: user.id, week_start: "2026-06-01", comment: "Rever horas extras", reviewer: reviewer
    )

    expect(Notifications::SendPushService).to have_received(:call).with(
      user: user,
      title: "Jornada semanal reprovada",
      body: "Sua jornada da semana de 01/06 a 07/06 foi reprovada. Motivo: Rever horas extras"
    )
  end

  it "keeps the review when the push fails" do
    allow(Notifications::SendPushService).to receive(:call).and_raise(StandardError, "FCM down")

    review = described_class.call(
      user_id: user.id, week_start: "2026-06-01", comment: "Rever horas extras", reviewer: reviewer
    )

    expect(review).to be_persisted
    expect(review).to be_rejected
  end
end
