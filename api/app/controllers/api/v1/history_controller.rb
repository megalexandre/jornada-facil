# frozen_string_literal: true

module Api
  module V1
    # Histórico da semana do próprio usuário autenticado. Reaproveita o mesmo
    # cálculo da revisão semanal (UserDetailService), mas o usuário vem do token
    # e o acesso é gateado por history:view (não weekly_review:view).
    class HistoryController < ApplicationController
      before_action :authenticate_user!

      def show
        verify "history:view"
        contract = ::WeeklyReviews::WeekContract.from_params(params)
        detail = ::WeeklyReviews::UserDetailService.call(
          user_id: current_user.id,
          week_start: contract.week_start
        )
        render json: WeeklyReviewDetailSerializer.new(detail).as_json, status: :ok
      end
    end
  end
end
