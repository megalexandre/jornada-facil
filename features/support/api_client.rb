# frozen_string_literal: true

require "httparty"

# Cliente HTTP mínimo para dirigir a API nos cenários. Envia/recebe JSON e
# anexa o Bearer token quando informado.
class ApiClient
  # host_header: valor a enviar no cabeçalho Host. Necessário quando a API é
  # alcançada pelo nome do serviço do compose (ex.: `api:3000`), porque o Rails 8
  # em desenvolvimento só aceita localhost/IPs (Host Authorization). Mandar
  # `Host: localhost` faz o Rails aceitar sem precisar mexer na config da API.
  def initialize(base_url, host_header: nil)
    @base = base_url.chomp("/")
    @host_header = host_header
  end

  def get(path, token: nil)
    request(:get, path, nil, token)
  end

  def post(path, body = {}, token: nil)
    request(:post, path, body, token)
  end

  def patch(path, body = {}, token: nil)
    request(:patch, path, body, token)
  end

  private

  def request(method, path, body, token)
    headers = { "Content-Type" => "application/json" }
    headers["Host"] = @host_header if @host_header
    headers["Authorization"] = "Bearer #{token}" if token
    options = { headers: headers }
    options[:body] = body.to_json unless body.nil?
    HTTParty.public_send(method, "#{@base}#{path}", **options)
  end
end
