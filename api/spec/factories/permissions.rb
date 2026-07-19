# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:resource) { |n| "resource_#{n}" }
    action { "read" }
    description { Faker::Lorem.sentence }
  end
end
