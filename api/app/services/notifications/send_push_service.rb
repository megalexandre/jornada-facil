# frozen_string_literal: true

module Notifications
  # Envia um push para todos os aparelhos registrados do usuário. Tokens que
  # o FCM não reconhece mais são removidos (aparelho desinstalou o app ou o
  # token rotacionou); os demais erros sobem para o chamador.
  class SendPushService
    def self.call(user:, title:, body:)
      new(user: user, title: title, body: body).call
    end

    def initialize(user:, title:, body:)
      @user = user
      @title = title
      @body = body
    end

    def call
      sent = 0

      @user.device_tokens.each do |device_token|
        Fcm::Client.send_notification(token: device_token.token, title: @title, body: @body)
        sent += 1
      rescue Fcm::Client::StaleToken
        device_token.destroy
      end

      { sent: sent }
    end
  end
end
