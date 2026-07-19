# frozen_string_literal: true

module Auth
  # Raised when a username/password pair does not authenticate a live user.
  class InvalidCredentials < ApplicationError
    def initialize(message = "Invalid username or password")
      super
    end

    def status
      :unauthorized
    end
  end
end
