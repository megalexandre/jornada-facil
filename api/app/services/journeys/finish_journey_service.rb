# frozen_string_literal: true

module Journeys
  # Finishes one of the user's journeys at the server clock, recording where
  # the user was (when the device had a fix). Scoped to the user's own
  # journeys, so someone else's id surfaces as RecordNotFound.
  class FinishJourneyService
    def self.call(user:, id:, location: nil)
      new(user:, id:, location:).call
    end

    def initialize(user:, id:, location: nil)
      @user = user
      @id = id
      @location = location
    end

    def call
      journey = @user.journeys.find_by(id: @id) || raise(RecordNotFound.new("Journey"))
      raise AlreadyFinished unless journey.open?

      journey.update!(finished_at: Time.current, finished_location: @location)
      journey
    end
  end
end
