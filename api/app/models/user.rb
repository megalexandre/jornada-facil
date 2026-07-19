# frozen_string_literal: true

class User < ApplicationRecord
  include SoftDeletable

  has_secure_password

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :journeys, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  validates :username, presence: true, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?
  validates :name, presence: true

  # Usuários que batem ponto (aparecem na revisão semanal e podem abrir jornada).
  scope :journey_trackers, -> { where(tracks_journey: true) }
end
