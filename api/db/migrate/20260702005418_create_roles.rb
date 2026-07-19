# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.text :description

      t.uuid :created_by
      t.uuid :updated_by
      t.datetime :deleted_at, index: true

      t.timestamps
    end

    add_index :roles, :name, unique: true
  end
end
