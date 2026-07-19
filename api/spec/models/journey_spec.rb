# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journey, type: :model do
  describe "validations" do
    it "requires started_at" do
      journey = build(:journey, started_at: nil)
      expect(journey).not_to be_valid
      expect(journey.errors[:started_at]).to include("can't be blank")
    end

    it "rejects finished_at earlier than started_at" do
      journey = build(:journey, started_at: Time.current, finished_at: 1.hour.ago)
      expect(journey).not_to be_valid
      expect(journey.errors[:finished_at]).to be_present
    end

    it "allows a journey without finished_at (open journey)" do
      expect(build(:journey)).to be_valid
    end
  end

  describe "multiple journeys per day" do
    it "allows the same user to have several finished journeys on the same day" do
      user = create(:user)
      morning = create(:journey, user: user, started_at: 8.hours.ago, finished_at: 5.hours.ago)
      afternoon = create(:journey, user: user, started_at: 3.hours.ago, finished_at: 1.hour.ago)

      expect([ morning, afternoon ]).to all(be_persisted)
    end
  end

  describe "one open journey per user (partial unique index)" do
    it "rejects a second open journey at the database level" do
      user = create(:user)
      create(:journey, user: user)

      expect {
        build(:journey, user: user).save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows open journeys for different users" do
      create(:journey)
      expect(create(:journey)).to be_persisted
    end
  end

  describe "#open?" do
    it "is true without finished_at and false with it" do
      expect(build(:journey).open?).to be true
      expect(build(:journey, :finished).open?).to be false
    end
  end
end
