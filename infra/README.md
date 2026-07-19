# Infraestrutura

Este diretório contém a configuração da infraestrutura local para desenvolvimento.

## PostgreSQL + PostGIS

Para iniciar o banco de dados PostgreSQL com suporte a PostGIS, execute:

```bash
docker-compose up -d
```

Para parar o banco de dados:

```bash
docker-compose down
```

Para visualizar os logs:

```bash
docker-compose logs -f postgres
```

### Configurações

- **Host**: localhost
- **Port**: 5432
- **Usuario**: postgres
- **Senha**: postgres
- **Banco de dados**: api_development

Após iniciar o container, execute no diretório da aplicação Rails:

```bash
cd ../api
rails db:create
rails db:schema:load
```
