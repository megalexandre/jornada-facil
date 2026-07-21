# frozen_string_literal: true

# postgis_tiger_geocoder e postgis_topology já estavam habilitadas no banco
# api_development (bootstrap automático da imagem postgis/postgis, que só roda
# contra o banco de POSTGRES_DB) sem nunca ter passado por uma migration. O
# schema.rb assume os schemas tiger/topology já existentes, mas
# `CREATE EXTENSION ... SCHEMA x` não cria o schema sozinho — falha em qualquer
# banco novo (api_test, CI, outra máquina). Ver config/application.rb.
class EnablePostgisExtensions < ActiveRecord::Migration[8.1]
  def up
    enable_extension "postgis" unless extension_enabled?("postgis")
    enable_extension "fuzzystrmatch" unless extension_enabled?("fuzzystrmatch")

    execute "CREATE SCHEMA IF NOT EXISTS tiger"
    execute "CREATE SCHEMA IF NOT EXISTS tiger_data"
    enable_extension "tiger.postgis_tiger_geocoder" unless extension_enabled?("postgis_tiger_geocoder")

    execute "CREATE SCHEMA IF NOT EXISTS topology"
    enable_extension "topology.postgis_topology" unless extension_enabled?("postgis_topology")
  end

  def down
    disable_extension "postgis_topology", force: :cascade
    disable_extension "postgis_tiger_geocoder", force: :cascade
    disable_extension "fuzzystrmatch", force: :cascade
    disable_extension "postgis", force: :cascade
  end
end
