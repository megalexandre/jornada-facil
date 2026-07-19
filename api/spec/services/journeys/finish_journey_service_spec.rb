# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::FinishJourneyService do
  let(:user) { create(:user) }

  it "finishes the user's open journey at the server clock" do
    journey = create(:journey, user: user, started_at: 1.hour.ago)

    finished = described_class.call(user: user, id: journey.id)

    expect(finished.id).to eq(journey.id)
    expect(finished.finished_at).to be_within(2.seconds).of(Time.current)
  end

  it "raises RecordNotFound for another user's journey" do
    journey = create(:journey)

    expect { described_class.call(user: user, id: journey.id) }.to raise_error(RecordNotFound)
  end

  it "raises RecordNotFound for an unknown id" do
    expect { described_class.call(user: user, id: SecureRandom.uuid) }.to raise_error(RecordNotFound)
  end

  it "raises AlreadyFinished when the journey is already finished" do
    journey = create(:journey, :finished, user: user)

    expect { described_class.call(user: user, id: journey.id) }.to raise_error(Journeys::AlreadyFinished)
  end
end
