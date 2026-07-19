# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < ApplicationController
        before_action :authenticate_user!

        # GET /api/v1/auth/me
        def show
          render json: { user: AuthUserSerializer.new(current_user).as_json }, status: :ok
        end
      end
    end
  end
end
