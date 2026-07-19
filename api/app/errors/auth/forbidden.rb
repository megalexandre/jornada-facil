# frozen_string_literal: true

module Auth
  # Raised when an authenticated user lacks the required permission.
  class Forbidden < ApplicationError
    def initialize(message = "Forbidden")
      super
    end

    def status
      :forbidden
    end
  end
end
