# frozen_string_literal: true

require "net/http"

module Fcm
  # Cliente mínimo da API FCM HTTP v1 (envio de push). Autentica com a
  # service account do Firebase guardada em Rails credentials (fcm:
  # service_account_json, o JSON baixado do console) e envia uma notificação
  # para um token de aparelho.
  class Client
    SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

    # Token que o FCM não reconhece mais (app desinstalado, token rotacionado):
    # o chamador deve descartá-lo em vez de tentar de novo.
    class StaleToken < StandardError; end

    class Error < StandardError; end

    class NotConfigured < ApplicationError
      def initialize
        super("FCM service account not configured")
      end
    end

    def self.send_notification(token:, title:, body:)
      new.send_notification(token: token, title: title, body: body)
    end

    def send_notification(token:, title:, body:)
      uri = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request.body = {
        message: {
          token: token,
          notification: { title: title, body: body }
        }
      }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      return true if response.is_a?(Net::HTTPSuccess)
      raise StaleToken if stale_token_response?(response)

      raise Error, "FCM respondeu #{response.code}: #{response.body}"
    end

    private

    # Credencial memoizada por processo; a lib renova o access token sozinha
    # quando expira.
    def self.authorizer
      @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(service_account_json),
        scope: SCOPE
      )
    end

    def self.service_account_json
      Rails.application.credentials.dig(:fcm, :service_account_json) or raise NotConfigured
    end

    def access_token
      authorizer = self.class.authorizer
      authorizer.fetch_access_token! if authorizer.access_token.nil? || authorizer.expired?
      authorizer.access_token
    end

    def project_id
      @project_id ||= JSON.parse(self.class.service_account_json).fetch("project_id")
    end

    def stale_token_response?(response)
      response.code == "404" || response.body.to_s.include?("UNREGISTERED")
    end
  end
end
