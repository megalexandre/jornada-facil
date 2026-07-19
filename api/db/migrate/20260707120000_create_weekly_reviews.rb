# frozen_string_literal: true

class CreateWeeklyReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_reviews, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.uuid :reviewer_id, null: false
      t.date :week_start, null: false
      t.string :status, null: false
      t.text :comment
      t.uuid :created_by
      t.uuid :updated_by

      t.timestamps
    end

    add_foreign_key :weekly_reviews, :users, column: :reviewer_id
    add_index :weekly_reviews, [ :user_id, :week_start ], unique: true
  end
end
