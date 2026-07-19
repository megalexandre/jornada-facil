# frozen_string_literal: true

require "rspec/expectations"
require_relative "api_client"

# World compartilhado por todos os steps. Expõe o cliente da API, a última
# resposta e o token corrente, além do helper de login.
#
# API_BASE_URL:
#   - dentro do compose (serviço `tests`): http://api:3000
#   - fora / no dev container:             http://localhost:3000
module JornadaWorld
  include RSpec::Matchers

  def api
    @api ||= ApiClient.new(
      ENV.fetch("API_BASE_URL", "http://localhost:3000"),
      host_header: ENV["API_HOST_HEADER"] # ex.: "localhost" quando a API é `api:3000`
    )
  end

  # Autentica e guarda a resposta + o token para os steps seguintes.
  def login_as(username, password)
    @last_response = api.post("/api/v1/auth/login", { username: username, password: password })
    @token = @last_response.parsed_response.is_a?(Hash) ? @last_response.parsed_response["token"] : nil
  end

  attr_reader :last_response, :token
end

World(JornadaWorld)
