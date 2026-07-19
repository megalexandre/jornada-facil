# frozen_string_literal: true

module Journeys
  # Raised when opening a journey while the user already has one open.
  class AlreadyOpen < ApplicationError
    def initialize(message = "There is already an open journey")
      super
    end

    def status
      :unprocessable_content
    end
  end
end
