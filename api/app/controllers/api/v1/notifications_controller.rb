# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!

      def create
        verify "notification:create"

        contract = ::Notifications::SendContract.from_params(params)
        user = User.find_by(id: contract.user_id) or raise RecordNotFound, "User"

        result = ::Notifications::SendPushService.call(
          user: user,
          title: contract.title,
          body: contract.body
        )

        render json: result, status: :ok
      end
    end
  end
end
