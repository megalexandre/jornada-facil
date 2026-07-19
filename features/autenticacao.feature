# language: pt
Funcionalidade: Autenticação
  Como usuário cadastrado
  Quero autenticar com usuário e senha
  Para acessar o sistema

  Cenário: Login com credenciais válidas
    Quando faço login com "admin" e "Password123!"
    Então recebo um token de acesso
    E ao consultar meus dados vejo o usuário "admin"

  Cenário: Login com senha incorreta
    Quando faço login com "admin" e "senha-errada"
    Então a resposta tem status 401
