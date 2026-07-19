# frozen_string_literal: true

class Journey < ApplicationRecord
  include SoftDeletable

  belongs_to :user

  validates :started_at, presence: true
  validates :finished_at, comparison: { greater_than_or_equal_to: :started_at }, allow_nil: true

  scope :recent_first, -> { order(started_at: :desc) }

  def open?
    finished_at.nil?
  end
end
