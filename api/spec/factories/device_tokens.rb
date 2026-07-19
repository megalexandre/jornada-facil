# frozen_string_literal: true

FactoryBot.define do
  factory :device_token do
    association :user
    sequence(:token) { |n| "fcm-token-#{n}" }
    platform { "android" }
  end
end
