# frozen_string_literal: true

module Api
  module V1
    module Auth
      class LoginController < ApplicationController
        # POST /api/v1/auth/login
        def create
          login_param = ::Auth::LoginContract.from_params(params)

          login = ::Auth::LoginService.call(
            username: login_param.username,
            password: login_param.password
          )

          render json: LoginSerializer.new(login).as_json, status: :ok
        end
      end
    end
  end
end
