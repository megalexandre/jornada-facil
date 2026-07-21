# language: pt

Funcionalidade: Registro de ponto

  Regras de abertura e fechamento de jornada.

  Cenário: Administrador não registra jornada
    Dado que estou autenticado como "admin" com senha "Password123!"
    Quando tento abrir uma jornada
    Então a resposta tem status 403
    E a mensagem de erro é "Usuário não registra jornada"

  @wip
  Cenário: Funcionário abre e finaliza o ponto
    # Requer um usuário com tracks_journey=true semeado no banco (ex.: "funcionario").
    # Semeie-o em api/db/seeds.rb e remova a tag @wip para ligar este cenário.
    Dado que estou autenticado como "funcionario" com senha "Password123!"
    Quando abro uma jornada em latitude -23.5 e longitude -46.6
    Então a resposta tem status 201
    E a jornada está aberta
    Quando finalizo a jornada em latitude -23.5 e longitude -46.6
    Então a resposta tem status 200
    E a jornada está finalizada
