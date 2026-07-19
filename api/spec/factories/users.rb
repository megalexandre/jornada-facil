# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    email { Faker::Internet.email }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    bio { Faker::Lorem.sentence }

    trait :no_journey do
      tracks_journey { false }
    end
  end
end
