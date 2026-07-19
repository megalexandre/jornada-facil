# frozen_string_literal: true

module DeviceTokens
  # Registra o token FCM de um aparelho para o usuário autenticado. O token
  # identifica uma instalação, não o usuário: se já pertencia a outra conta
  # (aparelho compartilhado/trocado), é re-vinculado ao último usuário logado.
  class RegisterService
    def self.call(user:, token:, platform: nil)
      new(user: user, token: token, platform: platform).call
    end

    def initialize(user:, token:, platform: nil)
      @user = user
      @token = token
      @platform = platform
    end

    def call
      device_token = DeviceToken.find_or_initialize_by(token: @token)
      device_token.user = @user
      device_token.platform = @platform if @platform.present?
      raise InvalidParameters.new(device_token.errors) unless device_token.save

      device_token
    rescue ActiveRecord::RecordNotUnique
      # Corrida entre o find e o insert contra o índice único: na retentativa
      # o registro existente é encontrado e re-vinculado.
      retry
    end
  end
end
