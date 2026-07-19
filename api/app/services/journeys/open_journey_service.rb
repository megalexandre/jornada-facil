# frozen_string_literal: true

module Journeys
  # Opens a journey for the user at the server clock, recording where the
  # user was (when the device had a fix). Only one journey may be open at a
  # time (backed by a partial unique index on journeys).
  class OpenJourneyService
    def self.call(user:, location: nil)
      new(user:, location:).call
    end

    def initialize(user:, location: nil)
      @user = user
      @location = location
    end

    def call
      raise AlreadyOpen if @user.journeys.exists?(finished_at: nil)

      @user.journeys.create!(started_at: Time.current, started_location: @location)
    end
  end
end
