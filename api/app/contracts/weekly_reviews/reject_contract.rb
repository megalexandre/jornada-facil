# frozen_string_literal: true

module WeeklyReviews
  class RejectContract < WeekContract
    attribute :comment, :string

    validates :comment, presence: true
  end
end
