# frozen_string_literal: true

module Api
  module V1
    # Visão semanal do admin: todos os usuários com totais e status de revisão.
    class WeeklyReviewsController < ApplicationController
      before_action :authenticate_user!

      def index
        verify "weekly_review:view"
        contract = ::WeeklyReviews::WeekContract.from_params(params)
        summary = ::WeeklyReviews::SummaryService.call(week_start: contract.week_start)
        render json: WeeklyReviewSummarySerializer.new(summary).as_json, status: :ok
      end
    end
  end
end
