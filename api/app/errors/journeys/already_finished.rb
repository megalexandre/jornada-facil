# frozen_string_literal: true

module Journeys
  # Raised when finishing a journey that has already been finished.
  class AlreadyFinished < ApplicationError
    def initialize(message = "Journey already finished")
      super
    end

    def status
      :unprocessable_content
    end
  end
end
