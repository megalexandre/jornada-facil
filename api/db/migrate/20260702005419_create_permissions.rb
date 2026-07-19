# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.text :description

      t.uuid :created_by
      t.uuid :updated_by
      t.datetime :deleted_at, index: true

      t.timestamps
    end

    add_index :permissions, :name, unique: true
  end
end
