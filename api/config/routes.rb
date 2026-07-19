# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Versão do backend (público, lido na tela de login antes de autenticar).
      get "version", to: "version#show"

      namespace :auth do
        post :login, to: "login#create"
        get :me, to: "me#show"
      end

      resources :users, only: [ :index, :show ] do
        member do
          patch :restore
        end

        resources :journeys, only: [ :index ], module: :users

        resource :weekly_review, only: [ :show ], module: :users do
          post :approve
          post :reject
        end
      end

      resources :weekly_reviews, only: [ :index ]

      # Histórico da semana do próprio usuário (self-service); exige history:view.
      get "history", to: "history#show"

      resources :journeys, only: [ :index, :create ] do
        member do
          patch :finish
        end
      end

      resources :device_tokens, only: [ :create ]
      resources :notifications, only: [ :create ]
    end
  end
end
