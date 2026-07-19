# frozen_string_literal: true

module Notifications
  class SendContract < ApplicationContract
    attribute :user_id, :string
    attribute :title, :string
    attribute :body, :string

    validates :user_id, presence: true
    validates :title, presence: true
    validates :body, presence: true
  end
end
