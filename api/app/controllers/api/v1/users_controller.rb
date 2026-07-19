# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def index
        verify "users:view"
        users = User.order(:name)
        render json: users.map { |user| UserSerializer.new(user).as_json }, status: :ok
      end

      def show
        verify "users:view"
        # ::Users, not Users: the bare constant would resolve to Api::V1::Users
        # (the nested controllers namespace) instead of the service module.
        user = ::Users::GetUserService.call(id: params[:id])
        render json: UserSerializer.new(user).as_json, status: :ok
      end
    end
  end
end
