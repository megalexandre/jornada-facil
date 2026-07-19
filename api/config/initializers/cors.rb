# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# CORS para o app Flutter rodando no navegador (dev server usa porta
# aleatória em localhost). Auth vai no header Authorization (Bearer),
# sem cookies, então liberar origem em dev é seguro. Em produção as
# origens permitidas vêm de CORS_ORIGINS (separadas por vírgula).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.env.production? ? ENV.fetch("CORS_ORIGINS", "").split(",") : "*"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
