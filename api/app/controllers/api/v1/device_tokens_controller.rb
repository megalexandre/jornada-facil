# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/device_tokens — upsert idempotente do token do aparelho,
      # sempre sobre o current_user (self-service, sem verificação RBAC).
      def create
        device_token = DeviceTokens::RegisterService.call(
          user: current_user,
          token: params[:token],
          platform: params[:platform]
        )

        render json: DeviceTokenSerializer.new(device_token).as_json, status: :ok
      end
    end
  end
end
