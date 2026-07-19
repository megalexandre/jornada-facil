# frozen_string_literal: true

class CreateJourneys < ActiveRecord::Migration[8.1]
  def change
    create_table :journeys, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.uuid :created_by
      t.uuid :updated_by
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :journeys, :deleted_at
    add_index :journeys, [ :user_id, :started_at ]
    # A user may have many journeys per day, but only one open at a time.
    add_index :journeys, :user_id,
              unique: true,
              where: "finished_at IS NULL AND deleted_at IS NULL",
              name: "index_journeys_one_open_per_user"
  end
end
