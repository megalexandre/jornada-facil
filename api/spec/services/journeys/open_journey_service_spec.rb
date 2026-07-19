# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::OpenJourneyService do
  let(:user) { create(:user) }

  it "opens a journey at the server clock" do
    journey = described_class.call(user: user)

    expect(journey).to be_persisted
    expect(journey.user).to eq(user)
    expect(journey.started_at).to be_within(2.seconds).of(Time.current)
    expect(journey.finished_at).to be_nil
  end

  it "raises AlreadyOpen when the user already has an open journey" do
    create(:journey, user: user)

    expect { described_class.call(user: user) }.to raise_error(Journeys::AlreadyOpen)
  end

  it "allows opening a new journey the same day once the previous one is finished" do
    create(:journey, :finished, user: user)

    expect(described_class.call(user: user)).to be_persisted
  end

  it "is not blocked by another user's open journey" do
    create(:journey)

    expect(described_class.call(user: user)).to be_persisted
  end
end
