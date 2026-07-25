# frozen_string_literal: true

module Users
  # Shape of the employee payload sent by the admin (create/update). Password is
  # optional here: the User model already requires it on create (via
  # has_secure_password) and ignores it on update when blank.
  class EmployeeContract < ApplicationContract
    attribute :name, :string
    attribute :username, :string
    attribute :email, :string
    attribute :password, :string

    validates :name, presence: true
    validates :username, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
end
