# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # SQL dump (db/structure.sql) instead of the Ruby schema.rb: PostGIS extensions
    # like `postgis_tiger_geocoder`/`postgis_topology` need their own schemas
    # (`tiger`/`topology`) created before `CREATE EXTENSION ... SCHEMA x` — Postgres
    # doesn't create that schema itself, and schema.rb's `enable_extension` has no
    # way to emit the `CREATE SCHEMA` for it. pg_dump does, so a fresh database
    # (api_test, CI, another dev's machine) loads correctly from structure.sql
    # without depending on the postgis/postgis image's one-time bootstrap of
    # POSTGRES_DB. Dump every schema (not just "public") so those extension
    # schemas make it into the file.
    config.active_record.schema_format = :sql
    config.active_record.dump_schemas = :all
  end
end
