# frozen_string_literal: true

module Journeys
  # Geographic point sent by the app when opening or finishing a journey.
  # Optional (the device may not have a GPS fix), but when sent latitude and
  # longitude must come together and within valid ranges.
  class LocationContract < ApplicationContract
    FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

    attribute :latitude, :float
    attribute :longitude, :float

    validates :latitude, numericality: { in: -90..90 }, allow_nil: true
    validates :longitude, numericality: { in: -180..180 }, allow_nil: true
    validates :latitude, presence: true, unless: -> { longitude.nil? }
    validates :longitude, presence: true, unless: -> { latitude.nil? }

    def point
      return nil if latitude.nil?

      FACTORY.point(longitude, latitude)
    end
  end
end
