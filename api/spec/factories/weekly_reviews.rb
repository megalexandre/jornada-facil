# frozen_string_literal: true

FactoryBot.define do
  factory :weekly_review do
    association :user
    association :reviewer, factory: :user
    week_start { Date.current.beginning_of_week(:monday) }
    status { "approved" }

    trait :rejected do
      status { "rejected" }
      comment { "Horas inconsistentes" }
    end
  end
end
