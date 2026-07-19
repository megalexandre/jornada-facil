# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :phone
      t.text :bio

      t.uuid :created_by
      t.uuid :updated_by
      t.datetime :deleted_at, index: true

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
