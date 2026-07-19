# frozen_string_literal: true

class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.string :platform, null: false, default: "android"

      t.timestamps
    end

    add_index :device_tokens, :token, unique: true
  end
end
