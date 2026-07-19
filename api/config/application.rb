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

    # Only dump the app's own `public` schema. The PostGIS image auto-installs
    # `postgis_tiger_geocoder`, which adds `tiger`/`topology` to the search path;
    # with the default (`:schema_search_path`) their extension-owned tables leak
    # into db/schema.rb and make it un-loadable (create_table ... force: :cascade
    # can't drop tables owned by an extension). Restricting to "public" keeps only
    # our tables; the `enable_extension` lines remain, so the extension recreates
    # its own tables on load without conflict.
    config.active_record.dump_schemas = "public"
  end
end
