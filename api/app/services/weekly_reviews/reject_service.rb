# frozen_string_literal: true

module WeeklyReviews
  # Reprova a semana de um usuário com comentário obrigatório (upsert, como na
  # aprovação) e notifica o funcionário. Falha no push não desfaz a revisão.
  class RejectService
    def self.call(user_id:, week_start:, comment:, reviewer:)
      new(user_id:, week_start:, comment:, reviewer:).call
    end

    def initialize(user_id:, week_start:, comment:, reviewer:)
      @user_id = user_id
      @week_start = WeeklyReviews.normalize_week_start(week_start)
      @comment = comment
      @reviewer = reviewer
    end

    def call
      user = ::Users::GetUserService.call(id: @user_id)
      review = WeeklyReview.find_or_initialize_by(user: user, week_start: @week_start)
      review.update!(status: :rejected, comment: @comment, reviewer: @reviewer)

      notify(user, review)

      review
    end

    private

    def notify(user, review)
      period = "#{review.week_start.strftime('%d/%m')} a #{(review.week_start + 6).strftime('%d/%m')}"
      Notifications::SendPushService.call(
        user: user,
        title: "Jornada semanal reprovada",
        body: "Sua jornada da semana de #{period} foi reprovada. Motivo: #{review.comment}"
      )
    rescue StandardError => e
      Rails.logger.error("WeeklyReviews::RejectService push failed: #{e.message}")
    end
  end
end
