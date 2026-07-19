# frozen_string_literal: true

class JourneySerializer
  def initialize(journey)
    @journey = journey
  end

  def as_json
    {
      id: @journey.id,
      started_at: @journey.started_at.iso8601,
      finished_at: @journey.finished_at&.iso8601,
      started_location: location_json(@journey.started_location),
      finished_location: location_json(@journey.finished_location)
    }
  end

  private

  def location_json(point)
    return nil if point.nil?

    { latitude: point.y, longitude: point.x }
  end
end
