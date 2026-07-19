# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    def current_user
      return @current_user if defined?(@current_user)

      user_id = decoded_token && decoded_token[:user_id]
      @current_user = user_id && User.find_by(id: user_id)
    end

    def authenticate_user!
      render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
    end

    private

    def decoded_token
      @decoded_token ||= JsonWebToken.decode(bearer_token)
    end

    def bearer_token
      header = request.headers["Authorization"]
      header.split(" ").last if header&.start_with?("Bearer ")
    end
  end
end
