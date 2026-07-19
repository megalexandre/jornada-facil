# frozen_string_literal: true

module Api
  module V1
    module Users
      # Admin review of another user's journeys (view-only). Guarded by
      # users:view: inspecting a user's journeys is an act of inspecting that
      # user, not of operating one's own journey (journey:*).
      class JourneysController < ApplicationController
        before_action :authenticate_user!

        def index
          verify "users:view"
          user = ::Users::GetUserService.call(id: params[:user_id])
          journeys = user.journeys.recent_first
          render json: journeys.map { |journey| JourneySerializer.new(journey).as_json }, status: :ok
        end
      end
    end
  end
end
