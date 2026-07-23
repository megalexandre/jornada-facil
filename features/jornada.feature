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
    Dado que estou autenticado como "usuario" com senha "Senha123!"
    Quando abro uma jornada em latitude -23.5 e longitude -46.6
    Então a resposta tem status 201
    E a jornada está aberta
    Quando finalizo a jornada em latitude -23.5 e longitude -46.6
    Então a resposta tem status 200
    E a jornada está finalizada
