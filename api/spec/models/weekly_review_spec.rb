# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeeklyReview, type: :model do
  describe "validations" do
    it "accepts an approved review without comment" do
      expect(build(:weekly_review)).to be_valid
    end

    it "rejects an unknown status" do
      review = build(:weekly_review, status: "maybe")
      expect(review).not_to be_valid
      expect(review.errors[:status]).to be_present
    end

    it "requires a comment when rejected" do
      review = build(:weekly_review, status: "rejected", comment: nil)
      expect(review).not_to be_valid
      expect(review.errors[:comment]).to include("can't be blank")
    end

    it "accepts a rejected review with comment" do
      expect(build(:weekly_review, :rejected)).to be_valid
    end

    it "requires week_start to be a Monday" do
      review = build(:weekly_review, week_start: Date.new(2026, 7, 8))
      expect(review).not_to be_valid
      expect(review.errors[:week_start]).to include("must be a Monday")
    end

    it "allows only one review per user per week" do
      existing = create(:weekly_review)
      duplicate = build(
        :weekly_review,
        user: existing.user,
        week_start: existing.week_start
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:week_start]).to be_present
    end

    it "allows the same week for different users" do
      existing = create(:weekly_review)
      other = build(:weekly_review, week_start: existing.week_start)

      expect(other).to be_valid
    end
  end
end
