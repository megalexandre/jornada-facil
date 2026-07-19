# frozen_string_literal: true

# Regras da revisão semanal de jornadas. A API roda em UTC; todo o bucketing
# por dia, limites de semana e horários exibidos usam o fuso de negócio abaixo.
module WeeklyReviews
  TIME_ZONE = "America/Sao_Paulo"
  DAILY_MINUTES = 480
  EXPECTED_WEEK_MINUTES = 2400

  def self.time_zone
    ActiveSupport::TimeZone[TIME_ZONE]
  end

  # Qualquer data vira a segunda-feira da sua semana; nil = semana atual.
  # Datas inválidas são barradas antes, no WeekContract.
  def self.normalize_week_start(value)
    date = value.present? ? Date.parse(value.to_s) : time_zone.today
    date.beginning_of_week(:monday)
  end
end
