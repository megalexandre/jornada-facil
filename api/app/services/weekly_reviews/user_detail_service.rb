# frozen_string_literal: true

module WeeklyReviews
  # Detalhe da semana de um usuário: dias com intervalos, totais e a revisão
  # existente (ou nil, quando pendente).
  class UserDetailService
    def self.call(user_id:, week_start: nil)
      new(user_id:, week_start:).call
    end

    def initialize(user_id:, week_start:)
      @user_id = user_id
      @week_start = WeeklyReviews.normalize_week_start(week_start)
    end

    def call
      user = ::Users::GetUserService.call(id: @user_id)
      review = WeeklyReview.find_by(user: user, week_start: @week_start)
      computed = ComputeWeekService.call(
        journeys: week_journeys(user),
        week_start: @week_start,
        review: review
      )

      {
        user: user,
        week_start: @week_start,
        week_end: @week_start + 6,
        expected_minutes: EXPECTED_WEEK_MINUTES,
        review: review,
        days: computed.days,
        totals: computed.totals
      }
    end

    private

    def week_journeys(user)
      from = WeeklyReviews.time_zone.local(@week_start.year, @week_start.month, @week_start.day)
      user.journeys.where(started_at: from...(from + 7.days))
    end
  end
end
