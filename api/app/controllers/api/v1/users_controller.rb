# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      def index
        verify "users:view"
        scope = boolean(params[:include_inactive]) ? User.unscoped : User
        scope = scope.where(tracks_journey: true) if boolean(params[:tracks_journey])
        users = scope.order(:name)
        render json: users.map { |user| ::Users::EmployeeSerializer.new(user).as_json }, status: :ok
      end

      def show
        verify "users:view"
        # ::Users, not Users: the bare constant would resolve to Api::V1::Users
        # (the nested controllers namespace) instead of the service module.
        user = ::Users::GetUserService.call(id: params[:id])
        render json: ::Users::EmployeeSerializer.new(user).as_json, status: :ok
      end

      def create
        verify "users:create"
        contract = ::Users::EmployeeContract.from_params(params)
        user = ::Users::CreateEmployeeService.call(actor: current_user, attributes: contract.attributes)
        render json: ::Users::EmployeeSerializer.new(user).as_json, status: :created
      end

      def update
        verify "users:update"
        contract = ::Users::EmployeeContract.from_params(params)
        user = ::Users::UpdateEmployeeService.call(
          actor: current_user, id: params[:id], attributes: contract.attributes
        )
        render json: ::Users::EmployeeSerializer.new(user).as_json, status: :ok
      end

      def inactivate
        verify "users:delete"
        user = ::Users::InactivateEmployeeService.call(actor: current_user, id: params[:id])
        render json: ::Users::EmployeeSerializer.new(user).as_json, status: :ok
      end

      def restore
        verify "users:delete"
        user = ::Users::RestoreEmployeeService.call(actor: current_user, id: params[:id])
        render json: ::Users::EmployeeSerializer.new(user).as_json, status: :ok
      end

      private

      def boolean(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
