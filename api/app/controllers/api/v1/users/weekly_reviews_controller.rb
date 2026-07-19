# frozen_string_literal: true

module Api
  module V1
    module Users
      # Detalhe e decisão (aprovar/reprovar) da semana de um usuário.
      # Consultar exige weekly_review:view; decidir exige weekly_review:update.
      class WeeklyReviewsController < ApplicationController
        before_action :authenticate_user!

        def show
          verify "weekly_review:view"
          contract = ::WeeklyReviews::WeekContract.from_params(params)
          detail = ::WeeklyReviews::UserDetailService.call(
            user_id: params[:user_id],
            week_start: contract.week_start
          )
          render json: WeeklyReviewDetailSerializer.new(detail).as_json, status: :ok
        end

        def approve
          verify "weekly_review:update"
          contract = ::WeeklyReviews::WeekContract.from_params(params)
          review = ::WeeklyReviews::ApproveService.call(
            user_id: params[:user_id],
            week_start: contract.week_start,
            reviewer: current_user
          )
          render json: WeeklyReviewSerializer.new(review).as_json, status: :ok
        end

        def reject
          verify "weekly_review:update"
          contract = ::WeeklyReviews::RejectContract.from_params(params)
          review = ::WeeklyReviews::RejectService.call(
            user_id: params[:user_id],
            week_start: contract.week_start,
            comment: contract.comment,
            reviewer: current_user
          )
          render json: WeeklyReviewSerializer.new(review).as_json, status: :ok
        end
      end
    end
  end
end
