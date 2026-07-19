# frozen_string_literal: true

module Api
  module V1
    # Endpoint público de versão: permite conferir na tela do app qual build do
    # backend está no ar. APP_REVISION/APP_BUILD_TIME são assados na imagem pelo
    # CI (build-args no Dockerfile); 'dev' em execução local. Sem
    # before_action :authenticate_user! de propósito — é lido antes do login.
    class VersionController < ApplicationController
      def show
        render json: {
          version: ENV.fetch("APP_REVISION", "dev"),
          build_time: ENV.fetch("APP_BUILD_TIME", "")
        }, status: :ok
      end
    end
  end
end
