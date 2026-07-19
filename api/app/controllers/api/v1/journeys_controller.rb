# frozen_string_literal: true

module Api
  module V1
    class JourneysController < ApplicationController
      before_action :authenticate_user!

      def index
        verify "journey:view"
        journeys = current_user.journeys.recent_first
        render json: journeys.map { |journey| JourneySerializer.new(journey).as_json }, status: :ok
      end

      def create
        verify "journey:create"
        # Regra de domínio: admins (e afins) não batem ponto.
        raise ::Auth::Forbidden, "Usuário não registra jornada" unless current_user.tracks_journey

        contract = Journeys::LocationContract.from_params(params)
        journey = Journeys::OpenJourneyService.call(user: current_user, location: contract.point)
        render json: JourneySerializer.new(journey).as_json, status: :created
      end

      def finish
        verify "journey:update"
        contract = Journeys::LocationContract.from_params(params)
        journey = Journeys::FinishJourneyService.call(
          user: current_user, id: params[:id], location: contract.point
        )
        render json: JourneySerializer.new(journey).as_json, status: :ok
      end
    end
  end
end
