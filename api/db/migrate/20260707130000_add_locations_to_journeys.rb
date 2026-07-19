# frozen_string_literal: true

class AddLocationsToJourneys < ActiveRecord::Migration[8.1]
  def change
    add_column :journeys, :started_location, :st_point, geographic: true
    add_column :journeys, :finished_location, :st_point, geographic: true
  end
end
