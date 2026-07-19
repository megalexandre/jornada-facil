# frozen_string_literal: true

module Auth
  class LoginContract < ApplicationContract
    attribute :username, :string
    attribute :password, :string

    validates :username, presence: true
    validates :password, presence: true
  end
end
