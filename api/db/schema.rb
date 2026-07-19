# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_08_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "postgis"
  enable_extension "tiger.postgis_tiger_geocoder"
  enable_extension "topology.postgis_topology"

  create_table "device_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "platform", default: "android", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "journeys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.datetime "deleted_at"
    t.datetime "finished_at"
    t.geography "finished_location", limit: {srid: 4326, type: "st_point", geographic: true}
    t.datetime "started_at", null: false
    t.geography "started_location", limit: {srid: 4326, type: "st_point", geographic: true}
    t.datetime "updated_at", null: false
    t.uuid "updated_by"
    t.uuid "user_id", null: false
    t.index ["deleted_at"], name: "index_journeys_on_deleted_at"
    t.index ["user_id", "started_at"], name: "index_journeys_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_journeys_on_user_id"
    t.index ["user_id"], name: "index_journeys_one_open_per_user", unique: true, where: "((finished_at IS NULL) AND (deleted_at IS NULL))"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.text "description"
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by"
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "role_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "permission_id", null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by"
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.boolean "tracks_journey", default: true, null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by"
    t.string "username", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "weekly_reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.uuid "created_by"
    t.uuid "reviewer_id", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.uuid "updated_by"
    t.uuid "user_id", null: false
    t.date "week_start", null: false
    t.index ["user_id", "week_start"], name: "index_weekly_reviews_on_user_id_and_week_start", unique: true
    t.index ["user_id"], name: "index_weekly_reviews_on_user_id"
  end

  add_foreign_key "device_tokens", "users"
  add_foreign_key "journeys", "users"
  add_foreign_key "role_permissions", "permissions", on_delete: :cascade
  add_foreign_key "role_permissions", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
  add_foreign_key "weekly_reviews", "users"
  add_foreign_key "weekly_reviews", "users", column: "reviewer_id"
end
