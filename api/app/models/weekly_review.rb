# frozen_string_literal: true

# Decisão do admin sobre a semana de um usuário. "Pendente" é a ausência de
# registro — só aprovações e reprovações são gravadas, uma por (user, semana).
class WeeklyReview < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User"

  enum :status, { approved: "approved", rejected: "rejected" }, validate: true

  validates :week_start, presence: true, uniqueness: { scope: :user_id }
  validates :comment, presence: true, if: :rejected?
  validate :week_start_must_be_monday

  private

  def week_start_must_be_monday
    return if week_start.nil? || week_start.monday?

    errors.add(:week_start, "must be a Monday")
  end
end
