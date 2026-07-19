# frozen_string_literal: true

class DeviceToken < ApplicationRecord
  PLATFORMS = %w[android ios web].freeze

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :platform, presence: true, inclusion: { in: PLATFORMS }
end
