# frozen_string_literal: true

FactoryBot.define do
  factory :journey do
    association :user
    started_at { Time.current }

    trait :finished do
      started_at { 8.hours.ago }
      finished_at { Time.current }
    end
  end
end
