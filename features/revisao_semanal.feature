# language: pt
@wip
Funcionalidade: Revisão semanal (admin)
  # Esqueleto: aprovar/rejeitar a semana de um funcionário exige montar dados de
  # uma semana (jornadas) no banco. Preencha os steps pendentes em
  # features/step_definitions/revisao_semanal_steps.rb e remova @wip quando
  # o cenário de dados estiver pronto.

  Cenário: Administrador aprova a semana de um funcionário
    Dado que estou autenticado como "admin" com senha "Password123!"
    E existe um funcionário com uma semana registrada
    Quando aprovo a semana desse funcionário
    Então a resposta tem status 200
