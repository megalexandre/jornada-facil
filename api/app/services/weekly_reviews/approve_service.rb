# frozen_string_literal: true

module WeeklyReviews
  # Aprova a semana de um usuário (upsert: o admin pode mudar uma decisão
  # anterior; aprovar descarta o comentário de uma reprovação antiga) e
  # notifica o funcionário. Falha no push não desfaz a revisão.
  class ApproveService
    def self.call(user_id:, week_start:, reviewer:)
      new(user_id:, week_start:, reviewer:).call
    end

    def initialize(user_id:, week_start:, reviewer:)
      @user_id = user_id
      @week_start = WeeklyReviews.normalize_week_start(week_start)
      @reviewer = reviewer
    end

    def call
      user = ::Users::GetUserService.call(id: @user_id)
      review = WeeklyReview.find_or_initialize_by(user: user, week_start: @week_start)
      review.update!(status: :approved, comment: nil, reviewer: @reviewer)

      notify(user, review)

      review
    end

    private

    def notify(user, review)
      period = "#{review.week_start.strftime('%d/%m')} a #{(review.week_start + 6).strftime('%d/%m')}"
      Notifications::SendPushService.call(
        user: user,
        title: "Jornada semanal aprovada",
        body: "Sua jornada da semana de #{period} foi aprovada."
      )
    rescue StandardError => e
      Rails.logger.error("WeeklyReviews::ApproveService push failed: #{e.message}")
    end
  end
end
