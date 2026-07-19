# frozen_string_literal: true

class WeeklyReviewSerializer
  def initialize(review)
    @review = review
  end

  def as_json
    {
      id: @review.id,
      status: @review.status,
      comment: @review.comment,
      week_start: @review.week_start.iso8601,
      reviewer_name: @review.reviewer.name,
      reviewed_at: @review.updated_at.iso8601
    }
  end
end
