# frozen_string_literal: true

# Steps da revisão semanal — esqueleto. Enquanto pendentes, aparecem em amarelo
# no perfil `wip` (cucumber -p wip) e são pulados no perfil default.

Given("existe um funcionário com uma semana registrada") do
  pending("Semear um funcionário com jornadas de uma semana (api/db/seeds.rb) e guardar o id")
end

When("aprovo a semana desse funcionário") do
  # Endpoint real: POST /api/v1/users/:id/weekly_review/approve  { week_start: "AAAA-MM-DD" }
  pending("Chamar approve com o id do funcionário e o início da semana")
end
