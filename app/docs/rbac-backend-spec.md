# Especificação de Backend RBAC + Autenticação
## App Jornada (FJ Telecom)

**Versão:** 1.0  
**Data:** Julho 2026  
**Status:** Especificação de Arquitetura (aprovada para implementação)

---

## Seção 0 — Visão Geral e Objetivos

### Contexto de Negócio

O app Flutter "jornada" é uma solução de registro de ponto/attendance para FJ Telecom, integrada com autenticação biométrica (fingerprint/face) do aparelho e verificação de localização via geofence. Hoje, o app funciona **completamente offline e local**: não existe login real, não há persistência em servidor, e todas as permissões/papéis são hardcoded em um usuário único de mock.

Para que o sistema funcione em produção com múltiplos usuários, papéis (roles) configuráveis, e validação de permissões no servidor, é necessário desenhar e implementar:

1. **Autenticação real**: login com credenciais (email + senha), emissão de tokens seguros (JWT), refresh e logout.
2. **Autorização (RBAC) dinâmica**: um sistema de papéis (Gestor, Colaborador, e futuros) com permissões mapeadas em banco de dados, permitindo que novos papéis sejam adicionados via administração sem alteração de código.
3. **Contrato de API estável**: endpoints que o app Flutter possa consumir de forma confiável, preservando o esquema de permissões já existente no frontend (`"resource:action"` como string).

### Objetivos

- Desenhar um modelo de dados RBAC agnóstico de stack (válido para Node, Python, Java, Go, etc.).
- Descrever fluxos de autenticação (login/token/refresh/logout) e autorização (resolução de permissões por request).
- Documentar endpoints REST necessários (auth, usuário, roles, permissions, atribuições).
- Fornecer um contrato JSON/HTTP que permita o app Flutter evoluir sem quebras e que suporte a administração dinâmica de papéis.

### Fora de Escopo

- **Implementação de código backend**: este documento especifica *o quê* fazer, não *como* fazer em uma linguagem/framework particular.
- **Mudanças no app Flutter** (exceto para apontar explicitamente um "gap" entre o modelo Dart atual e o que o backend retornará): o frontend **já tem** o esqueleto pronto (`UserModel.fromJson`, `can()`, uso de permissões na UI), apenas precisa conectar ao backend real.
- **Infraestrutura** (hosting, CI/CD, backups): fora de escopo.
- **Funcionalidades de negócio** além de RBAC/auth (lógica de geofence, cálculo de horas, integrações com folha de pagamento): mencionadas apenas onde relevantes ao escopo de autorização.

---

## Seção 1 — Modelo de Dados RBAC Dinâmico

### Entidades Principais

O sistema RBAC é implementado através de 5 tabelas relacionais:

#### 1.1 — Tabela `users`

Armazena informações de cada usuário cadastrado.

| Campo | Tipo | Constraints | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID/INT | PK | Identificador único do usuário; UUID recomendado (mais seguro que serial incremental). |
| `name` | TEXT | NOT NULL | Nome completo do usuário. |
| `email` | TEXT | NOT NULL, UNIQUE | Endereço de email único (usado para login). |
| `password_hash` | TEXT | NOT NULL | Hash da senha (ex.: bcrypt), nunca retornar em resposta JSON. |
| `image_base64` | TEXT | nullable | Foto de perfil em base64 (ou URL, a decidir durante implementação; retorna em `/me`). |
| `image_url` | TEXT | nullable | URL de foto se preferir URL em vez de base64 (apenas uma das duas é usada). |
| `status` | ENUM | DEFAULT 'active' | `active`, `inactive`, `suspended`; usado para desativar usuários sem deletar. |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Quando o usuário foi criado. |
| `updated_at` | TIMESTAMP | DEFAULT NOW() ON UPDATE NOW() | Quando o usuário foi atualizado pela última vez. |
| `last_login` | TIMESTAMP | nullable | Timestamp do último login bem-sucedido (opcional, útil para auditoria). |

**Notas:**
- `email` é o identificador único para login (não criar logins por username).
- `password_hash` **nunca** deve ser retornado em qualquer resposta JSON.
- `image_base64` ou `image_url`: escolher uma abordagem (recomenda-se URL para reduzir tamanho de payload, mas base64 funciona se a foto for pequena e o app Flutter já espera base64).

#### 1.2 — Tabela `roles`

Armazena os papéis (Gestor, Colaborador, RH, Admin, etc.) que podem ser atribuídos a usuários.

| Campo | Tipo | Constraints | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID/INT | PK | Identificador único do papel. |
| `name` | TEXT | NOT NULL, UNIQUE | Nome do papel (ex.: "gestor", "colaborador", "rh", "admin"). Case-sensitive; recomenda-se lowercase. |
| `description` | TEXT | nullable | Descrição legível do papel (ex.: "Gestor de equipe de campo"). |
| `is_system` | BOOLEAN | DEFAULT FALSE | Se TRUE, o papel não pode ser deletado (protege roles-base como "Colaborador"). |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Quando o papel foi criado. |
| `updated_at` | TIMESTAMP | DEFAULT NOW() ON UPDATE NOW() | Quando o papel foi atualizado. |

**Notas:**
- `is_system = TRUE` para "gestor" e "colaborador" (seed inicial) impede que sejam deletados acidentalmente.
- Futuros papéis (ex.: "rh", "admin") terão `is_system = FALSE` e poderão ser editados/deletados enquanto não tiverem usuários associados.

#### 1.3 — Tabela `permissions`

Armazena as permissões individuais: cada combinação de `resource` + `action`.

| Campo | Tipo | Constraints | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID/INT | PK | Identificador único. |
| `resource` | TEXT | NOT NULL | Recurso (ex.: "journey", "history", "profile", "team", "settings"). |
| `action` | TEXT | NOT NULL | Ação (ex.: "view", "create", "update", "delete"). |
| `UNIQUE(resource, action)` | COMPOSITE | NOT NULL | Garante que a dupla resource:action é única (ex., não há dois "journey:view"). |
| `description` | TEXT | nullable | Descrição legível (ex.: "Visualizar registros de ponto pessoais"). |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Quando a permissão foi criada. |

**Notas:**
- A permissão em si é identificada pela dupla `(resource, action)`, que é convertida em string `"resource:action"` para transmitir ao frontend.
- Exemplo de seed inicial: `journey:view`, `history:view`, `profile:view`, `history:view:team` (escopo de equipe para Gestor).
- A criação de novas permissões deve ser feita via migration/seed, não via admin UI (ver Seção 4 para justificativa).

#### 1.4 — Tabela `role_permissions`

Associação N:N entre papéis e permissões.

| Campo | Tipo | Constraints | Descrição |
|-------|------|-----------|-----------|
| `role_id` | UUID/INT | FK → `roles.id`, PK part | Referência ao papel. |
| `permission_id` | UUID/INT | FK → `permissions.id`, PK part | Referência à permissão. |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Quando a associação foi criada. |

**Notas:**
- Chave primária composta: `(role_id, permission_id)`.
- Nenhuma coluna `id` própria — a identidade é a dupla (role, permission).

#### 1.5 — Tabela `user_roles`

Associação N:N entre usuários e papéis. **Decisão arquitetural: N:N, não 1:N.**

| Campo | Tipo | Constraints | Descrição |
|-------|------|-----------|-----------|
| `user_id` | UUID/INT | FK → `users.id`, PK part | Referência ao usuário. |
| `role_id` | UUID/INT | FK → `roles.id`, PK part | Referência ao papel. |
| `assigned_at` | TIMESTAMP | DEFAULT NOW() | Quando a atribuição foi feita. |
| `assigned_by` | UUID/INT | FK → `users.id`, nullable | ID do admin que fez a atribuição (para auditoria). |

**Notas:**
- Chave primária composta: `(user_id, role_id)`.
- Um usuário pode ter **múltiplos papéis simultaneamente** (ex.: um Gestor que também exerce função de Colaborador em outro contexto, ou um Admin que vê tudo).
- Resolução de permissões: union (DISTINCT) de todas as permissões dos todos os papéis do usuário.

**Por que N:N em vez de 1:N?**

- **1:N (um papel por usuário):** simples em queries, mas força a criação de roles combinados ("gestor_e_colaborador") conforme a matriz de negócio cresce, levando a explosão combinatória.
- **N:N (múltiplos papéis por usuário):** mais flexível, escalável, e se encaixa perfeitamente no requisito "futuros papéis virão via administração" — permite que um usuário acumule papéis sem duplicar permissões ou criar combinados explosivos. O custo extra é apenas a tabela de junção e um `UNION` nas queries de resolução — negligenciável.
- Decisão final: **N:N recomendado**; se a implementação inicial preferir 1:N (mais simples), é apenas um caso particular de N:N e pode ser refatorado depois sem quebra de contrato JSON.

### Resolução de Permissões Efetivas

Quando o backend precisa verificar se um usuário tem permissão `"history:view:team"`, executa:

```
1. SELECT roles FROM user_roles WHERE user_id = ?
2. SELECT permissions FROM role_permissions WHERE role_id IN (roles acima)
3. Convert permissions to strings "resource:action"
4. Return UNION/DISTINCT list to frontend
```

**Pseudocódigo:**

```
function getEffectivePermissions(user_id):
  roles = query("SELECT role_id FROM user_roles WHERE user_id = ?", user_id)
  
  permissions = query("
    SELECT DISTINCT p.resource, p.action
    FROM role_permissions rp
    JOIN permissions p ON rp.permission_id = p.id
    WHERE rp.role_id IN (roles acima)
  ")
  
  return [ p.resource + ':' + p.action for p in permissions ]
  // Ex.: ["journey:view", "history:view", "profile:view", "history:view:team", ...]
```

**Caching:** para não fazer essa query a cada request, recomenda-se cache curto (Redis/in-memory, TTL 5-15 minutos) ou embutir as roles no JWT e resolver permissions cachadas. Ver Seção 3 (Autenticação) para justificativa.

---

## Seção 2 — Alinhamento com o Contrato Existente do Frontend

### Compatibilidade com `UserModel.fromJson`

O app Flutter já possui a classe `UserModel` que sabe desserializar um JSON de usuário:

```dart
// lib/core/models/user_model.dart (código existente)
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    permissions: (json['permissions'] as List?)?.cast<String>() ?? const [],
    imageBase64: json['imageBase64'] as String?,
  );
}
```

**Contrato JSON esperado pelo endpoint `/me` (de acordo com o código acima):**

```json
{
  "name": "Alexandre Queiroz",
  "email": "alexandre@fjtelecom.com",
  "permissions": [
    "journey:view",
    "history:view",
    "profile:view",
    "history:view:team"
  ],
  "imageBase64": "iVBORw0KGgoAAAANS..."
}
```

**Regra de compatibilidade:** o backend **nunca deve remover** os campos `name`, `email`, `permissions`, `imageBase64` da resposta do endpoint `/me`. Pode adicionar novos campos (que o frontend ignorará) sem quebra retroativa.

### Gap Explícito: Campo `id` Ausente

O modelo Dart atual **não tem campo `id`** — é uma lacuna. O backend deve, desde o primeiro contrato, retornar um `id`:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Alexandre Queiroz",
  "email": "alexandre@fjtelecom.com",
  "permissions": [...],
  "imageBase64": "..."
}
```

**Ação esperada:** o frontend (em uma próxima iteração, fora do escopo deste documento) atualizará `UserModel` para incluir `id`. Por enquanto, o backend deve retornar o campo mesmo que o app não consuma — é um passo preparatório para futuras funcionalidades (ex.: endpoints de atribuição de roles `/users/{id}/roles` precisam do `id` para operar).

### Recursos (Resources) Atuais

O app conhece dois grupos de recursos (espelhados em `api/app/services/rbac.rb` e `app/lib/core/models/rbac.dart`):

**Recursos de domínio** (telas do usuário final):

- **`journey`**: registro de ponto (entrada/saída, "jornada").
- **`history`**: visualização de histórico de registros.
- **`profile`**: perfil/dados pessoais do usuário.

**Recursos de administração** (gateiam features administrativas no app):

- **`users`**: gestão/inspeção de usuários. Guarda `GET /api/v1/users` (listagem), `GET /api/v1/users/:id` e `GET /api/v1/users/:id/journeys` (revisão de jornadas por usuário) — todos com `users:view`.
- **`roles`**: gestão de papéis (endpoints futuros, Seção 4).
- **`permissions`**: catálogo de permissões (endpoints futuros, Seção 4).

### Serialização com Wildcards (payload de login/me)

A API serializa a lista `permissions` com atalhos que o `can()` do app já entende:

- `"resource:action"` — permissão explícita (ex.: `journey:view`).
- `"resource:*"` — todas as ações daquele resource (ex.: `users:*`).
- `"*"` — todas as ações de **todos** os resources do catálogo (domínio **+** administração). Só é emitido quando o usuário cobre o catálogo inteiro.

Desde a versão 1.1, os recursos de administração **são serializados** no payload junto com os de domínio — é assim que o app decide exibir a aba de Administração (`can('users:view')`). Os wildcards são apenas atalho de serialização (UX hint): o enforcement no servidor é sempre exact-match de `resource:action` contra o banco.

**Novo recurso para Gestor ver dados de equipe:**

Gestor precisa de uma forma de listar/aprovar registros de sua equipe. Existem duas abordagens:

#### Abordagem A (Recomendada): Permissão Distinta com Escopo Explícito

Criar uma permissão adicional: `history:view:team` (ou `journey:view:team` se desejar que gestores vejam também jornadas de terceiros).

- **Pros:** mantém o parser do frontend (`permissions.contains(string)`) trivial e sem mudança; compatível com `can()` atual; reusa o mesmo nome de resource ("history"), apenas com um identificador de escopo.
- **Cons:** expande ligeiramente a nomenclatura (agora temos `resource:action:scope` em vez de `resource:action`), mas é backward-compatible (a string é apenas maior).

#### Abordagem B: Dimensão de Escopo Genérica

Introduzir um "scope" como terceira dimensão: `history:view:own`, `history:view:team`, `history:view:all`, com o frontend entendendo essa estrutura.

- **Pros:** mais expressivo, genérico.
- **Cons:** exige mudança no frontend (`can()` precisaria parser de 3 dimensões); quebra a simplicidade atual; necessário apenas se quisermos aplicar "scope" a múltiplos resources, coisa ainda não provada.

**Decisão final: usar Abordagem A (recomendada).** Um admin no backend decide se "Gestor" recebe `history:view:team` e `journey:view:team`; o endpoint que retorna essas permissões as fornece como strings normais; o frontend continua usando `can()` trivial. A "semântica" de que `history:view:team` é "uma permissão de view com escopo de equipe" fica documentada aqui; o endpoint de negócio (`GET /history/team`) é que diferencia entre `history:view` (próprio) e `history:view:team` (equipe) e entrega o escopo certo.

---

## Seção 3 — Fluxo de Autenticação

### Visão Geral

Hoje, o app autentica-se **localmente** via biometria do aparelho (fingerprint/face). Isso não fornece identidade de servidor — apenas confirma "o aparelho foi desbloqueado". Para suportar RBAC real, é necessário um login com identidade de servidor (email + senha) que retorne tokens seguros.

### Arquitetura de Autenticação

A autenticação é dividida em **duas camadas independentes**:

1. **Camada de Identidade de Servidor** (novo, implementar):
   - Login: email + senha → backend valida credenciais → retorna `access_token` (JWT curto) + `refresh_token` (longo).
   - Refresh: `refresh_token` → novo `access_token` + opcional novo `refresh_token` (rotação).
   - Logout: revoga `refresh_token`, encerrando a sessão.

2. **Camada de Presença Local** (existente, manter):
   - Biometria do aparelho (fingerprint/face) continua como gate local.
   - Função: confirmar "é você mesmo segurando este telefone agora" (segundo fator).
   - **Não substitui** a identidade de servidor; é **independente** dela.

**Fluxo proposto:**

```
1. Usuário inicia o app
2. App verifica se há refresh_token armazenado localmente
   - Se SIM: tenta refresh (ir para passo 4)
   - Se NÃO: mostra tela de login
3. Tela de login: usuário digita email + senha
   POST /auth/login { "email": "...", "password": "..." }
   Backend: valida credenciais, retorna
   { "accessToken": "eyJhbGciOi...", "refreshToken": "eyJhbGciOi...", "user": {...} }
   App: armazena tokens em armazenamento seguro (Keychain/Keystore)
4. App mostra tela de biometria: "confirme sua identidade"
   Usuário autoriza fingerprint/face local
5. Se biometria falhar: nega acesso
   Se biometria suceder: carregar tela principal (MainScaffold)
6. Cada request para o backend leva access_token no header
   Authorization: Bearer eyJhbGciOi...
7. Quando access_token expira (15-30 min):
   POST /auth/refresh { "refreshToken": "..." }
   Backend: valida refresh_token, retorna novo access_token
   (opcional: também rotaciona refresh_token)
8. Logout: usuário tapa "Sair" (em user_drawer.dart, hoje TODO)
   POST /auth/logout { "refreshToken": "..." }
   Backend: revoga refresh_token, sessão encerrada
```

### Credenciais de Login

**Usuário:** email (unique no backend).  
**Senha:** no mínimo 8 caracteres (recomendação); backend armazena apenas hash (bcrypt ou equiv., nunca plaintext).  
**Primeiro login:** a senha é criada durante o onboarding/cadastro do usuário (fora do escopo desta especificação, mas mencionado para contexto).

### JWT (Access Token)

**Tipo:** JWT (JSON Web Token) assinado com HS256 ou RS256 (a decidir durante implementação).  
**Duração:** 15-30 minutos recomendado.  
**Payload (claims):**

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "alexandre@fjtelecom.com",
  "roles": ["colaborador", "gestor"],
  "iat": 1719921234,
  "exp": 1719921234 + 1800,
  "jti": "unique-token-id-for-revocation"
}
```

**Campos:**
- `sub` (subject): `user_id` (UUID ou string).
- `email`: email do usuário (informativo, permite debug).
- `roles`: **array de nomes de papéis**, não a lista de permissions. Ver justificativa abaixo.
- `iat` (issued at): timestamp UNIX.
- `exp` (expiration): timestamp UNIX (iat + TTL).
- `jti` (JWT ID): identificador único do token, opcional mas recomendado para revogação via blacklist.

**Por que `roles` no token, não `permissions`?**

- **Se embutirmos a lista de permissions no token:** toda vez que um admin muda a matriz de permissões de um papel (ex., Gestor ganha nova ação), o usuário não "enxerga" a mudança até o token expirar. Isso contradiz o requisito de "RBAC configurável dinamicamente" — mudanças devem refletir na próxima request ou login, não em 15-30 minutos.
- **Se embutirmos apenas `roles`:** o backend resolve `roles → permissions` a cada request (com cache), e mudanças administrativas refletem imediatamente ou em minutos (cache TTL). Trade-off: uma query extra por request, mas cacheável e negligenciável com Redis/cache local.
- **Decisão:** embutir apenas `roles`, resolver permissions "ao vivo" via middleware.

### Refresh Token

**Tipo:** JWT ou string opaco (a decidir durante implementação).  
**Duração:** 7-30 dias (mais longo que access_token).  
**Armazenamento no backend:** tabela `refresh_tokens` (ver modelo de dados estendido abaixo).  
**Rotação:** a cada `/auth/refresh`, gerar novo refresh_token e revogar o antigo (aumenta segurança contra token theft).

**Tabela de suporte (opcional, mas recomendada):**

```
refresh_tokens
  id: PK
  token_hash: HASH do refresh_token armazenado (nunca plaintext)
  user_id: FK users.id
  expires_at: TIMESTAMP
  revoked_at: TIMESTAMP (null se ativo)
  created_at: TIMESTAMP
```

Isso permite revogar tokens sem aguardar expiração (logout, mudança de senha, suspeita de roubo).

### Endpoints de Autenticação

#### `POST /auth/login`

**Corpo da request:**

```json
{
  "email": "alexandre@fjtelecom.com",
  "password": "minha-senha-secreta"
}
```

**Resposta (200 OK):**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Alexandre Queiroz",
    "email": "alexandre@fjtelecom.com",
    "permissions": ["journey:view", "history:view", "profile:view"],
    "imageBase64": "iVBORw0KGgoAAAANS..."
  }
}
```

**Erros:**
- `400 Bad Request`: email ou senha ausentes.
- `401 Unauthorized`: email não encontrado ou senha incorreta.
- `429 Too Many Requests`: limite de tentativas de login excedido (proteção contra brute-force).

#### `POST /auth/refresh`

**Corpo da request:**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Resposta (200 OK):**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Notas:**
- Backend valida o refresh_token (assinatura, expiração, não está na blacklist de revogados).
- Se válido, emite novo par de tokens.
- O refresh_token antigo é marcado como "revoked" (se houver tabela de tracking) ou simplesmente substituído.

**Erros:**
- `400 Bad Request`: refreshToken ausente.
- `401 Unauthorized`: refresh_token inválido, expirado ou revogado.

#### `POST /auth/logout`

**Corpo da request:**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Resposta (200 OK):**

```json
{
  "message": "Logged out successfully"
}
```

**Efeito:** marca o refresh_token como revogado no backend (se usar tabela) ou o descarta (se tokens forem stateless). Access_token atual ainda é válido até expiração (segundos/minutos), mas não pode ser refrescado.

**Notas:**
- Resolve o TODO em `lib/shared/widgets/layouts/user_drawer.dart` (logout não implementado).
- Recomenda-se também limpar tokens do armazenamento local no cliente (Keychain/Keystore).

---

## Seção 4 — Endpoints REST Necessários

### Classificação de Endpoints

- **Sem autenticação (públicos):** `/auth/login`, `/auth/refresh` (login não exige token; refresh exige apenas refresh_token válido, não access_token).
- **Com autenticação (protegidos por guard RBAC):** todos os demais; cada um declara uma permissão exigida.

### Endpoints de Autenticação (Públicos)

Já descritos em Seção 3.

- `POST /auth/login` — (nenhuma permissão exigida)
- `POST /auth/refresh` — (nenhuma permissão exigida)
- `POST /auth/logout` — (autenticado, mas qualquer usuário pode fazer logout dele mesmo)

### Endpoint de Usuário Autenticado

#### `GET /me`

Retorna as informações do usuário atualmente autenticado (extraído do `sub` do JWT).

**Permissão exigida:** nenhuma (qualquer usuário autenticado tem acesso).

**Resposta (200 OK):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Alexandre Queiroz",
  "email": "alexandre@fjtelecom.com",
  "permissions": ["journey:view", "history:view", "profile:view"],
  "imageBase64": "iVBORw0KGgoAAAANS...",
  "status": "active"
}
```

**Notas:**
- Permissions são calculadas/cacheadas conforme Seção 1.
- Campo `status` (active/inactive) é informativo; se um usuário estiver inativo, ele não deveria conseguir fazer login em primeiro lugar (validar em `/auth/login`).

#### `PATCH /me` (Opcional)

Permite que o usuário atualize seus próprios dados (nome, foto).

**Permissão exigida:** nenhuma (somente seu próprio recurso).

**Corpo da request:**

```json
{
  "name": "Alexandre Q. Silva",
  "imageBase64": "iVBORw0KGgoAAAANS..."
}
```

**Resposta (200 OK):** usuário atualizado (mesmo schema de `GET /me`).

**Notas:**
- Não permitir mudança de email ou senha aqui (seriam endpoints separados, fora de escopo).

### Administração de Papéis (Roles)

#### `GET /roles`

Lista todos os papéis (roles) cadastrados.

**Permissão exigida:** nenhuma (informativo); opcionalmente proteger com `roles:view` (nova permissão).

**Resposta (200 OK):**

```json
{
  "data": [
    {
      "id": "role-001",
      "name": "colaborador",
      "description": "Colaborador de campo",
      "is_system": true,
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-01-15T10:00:00Z"
    },
    {
      "id": "role-002",
      "name": "gestor",
      "description": "Gestor de equipe",
      "is_system": true,
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-01-15T10:00:00Z"
    }
  ]
}
```

#### `POST /roles`

Cria um novo papel.

**Permissão exigida:** `roles:create` (ou `admin:manage`).

**Corpo da request:**

```json
{
  "name": "rh",
  "description": "Departamento de RH"
}
```

**Resposta (201 Created):** papel criado (schema acima).

**Erros:**
- `400 Bad Request`: `name` já existe.
- `403 Forbidden`: sem permissão.

#### `GET /roles/:id`

Retorna detalhes de um papel específico (incluindo permissões associadas).

**Permissão exigida:** nenhuma ou `roles:view`.

**Resposta (200 OK):**

```json
{
  "id": "role-001",
  "name": "colaborador",
  "description": "Colaborador de campo",
  "is_system": true,
  "permissions": [
    {
      "id": "perm-001",
      "resource": "journey",
      "action": "view"
    },
    {
      "id": "perm-002",
      "resource": "history",
      "action": "view"
    },
    {
      "id": "perm-003",
      "resource": "profile",
      "action": "view"
    }
  ],
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z"
}
```

#### `PATCH /roles/:id`

Atualiza um papel.

**Permissão exigida:** `roles:update`.

**Corpo da request:**

```json
{
  "description": "Novo description do papel"
}
```

**Resposta (200 OK):** papel atualizado.

**Validação:** não permitir mudar `name` de um papel (`is_system=true`), apenas `description`.

#### `DELETE /roles/:id`

Deleta um papel.

**Permissão exigida:** `roles:delete`.

**Validação:**
- Não permitir delete de papéis com `is_system=true`.
- Não permitir delete de um papel que tenha usuários associados (ou deletar em cascata, a decidir durante implementação).

**Resposta (204 No Content):** papel deletado.

### Administração de Permissões

#### `GET /permissions`

Lista todas as permissões cadastradas.

**Permissão exigida:** nenhuma ou `permissions:view`.

**Resposta (200 OK):**

```json
{
  "data": [
    {
      "id": "perm-001",
      "resource": "journey",
      "action": "view",
      "description": "Visualizar registros de ponto pessoais"
    },
    {
      "id": "perm-002",
      "resource": "history",
      "action": "view",
      "description": "Visualizar histórico de pontos pessoais"
    },
    {
      "id": "perm-003",
      "resource": "history",
      "action": "view:team",
      "description": "Visualizar histórico de pontos da equipe (só Gestor)"
    }
  ]
}
```

**Notas:**
- Este endpoint é **apenas de leitura** (GET).
- Não há `POST /permissions` (ver justificativa abaixo).

**Por que não permitir criação de Permissions via API?**

Permissões (resource:action) são conceitos do **domínio de código** — cada resource e action correspondem a um endpoint ou lógica de negócio real no backend que sabe enforçá-la. Permitir que um admin crie permissões via UI poderia gerar permissões "mortas" (que ninguém valida de fato no código), poluindo o sistema e criando falsos positivos de segurança.

**Alternativa recomendada:** permissões são criadas via **migration/seed** conforme novos features são desenvolvidos. Se uma new action surgir (ex.: `update`, `delete`), é implementada no código, a permissão é criada em migration, e então um admin atribui ao papel apropriado via `/roles/:id/permissions`.

### Atribuição de Permissões a Papéis

#### `PUT /roles/:id/permissions`

Substitui a lista de permissões de um papel (idempotente).

**Permissão exigida:** `roles:update` ou `admin:manage`.

**Corpo da request:**

```json
{
  "permissionIds": ["perm-001", "perm-002", "perm-003", "perm-004"]
}
```

**Resposta (200 OK):**

```json
{
  "id": "role-002",
  "name": "gestor",
  "permissions": [
    { "id": "perm-001", "resource": "journey", "action": "view" },
    { "id": "perm-002", "resource": "history", "action": "view" },
    { "id": "perm-003", "resource": "profile", "action": "view" },
    { "id": "perm-004", "resource": "history", "action": "view:team" }
  ]
}
```

**Notas:**
- `PUT` (não `POST`) garante idempotência — se enviado duas vezes com mesma lista, resultado é idêntico.
- Substitui **todas** as permissões do papel; não é append/remove.

**Alternativa granular (opcional):**

Se preferir operações granulares:

- `POST /roles/:id/permissions/:permissionId` — adiciona uma permissão.
- `DELETE /roles/:id/permissions/:permissionId` — remove uma permissão.

(Menos recomendado por complexidade UI, mas válido.)

### Atribuição de Papéis a Usuários

#### `GET /users/:id/roles`

Lista os papéis atribuídos a um usuário.

**Permissão exigida:** `users:view` ou `admin:manage` (proteger leitura de dados de terceiros).

**Resposta (200 OK):**

```json
{
  "userId": "user-001",
  "roles": [
    {
      "id": "role-001",
      "name": "colaborador",
      "description": "Colaborador de campo"
    }
  ]
}
```

#### `PUT /users/:id/roles`

Atribui papéis a um usuário (substitui lista).

**Permissão exigida:** `users:update` ou `admin:manage`.

**Corpo da request:**

```json
{
  "roleIds": ["role-001", "role-002"]
}
```

**Resposta (200 OK):** usuário com papéis atualizados.

**Validação:** não permitir remover todos os papéis de um usuário (cada usuário deve ter pelo menos um papel).

#### Alternativa granular (opcional):

- `POST /users/:id/roles/:roleId` — adiciona papel.
- `DELETE /users/:id/roles/:roleId` — remove papel.

### Endpoints de Negócio com Escopo (Exemplos)

Estes endpoints não fazem parte do "core RBAC", mas demonstram como o sistema funciona na prática.

#### `GET /journey` (próprio)

Retorna os registros de ponto do usuário autenticado.

**Permissão exigida:** `journey:view`.

**Resposta (200 OK):**

```json
{
  "data": [
    {
      "id": "journey-001",
      "user_id": "user-001",
      "date": "2026-07-01",
      "entry_time": "09:00:00",
      "exit_time": "17:30:00",
      "status": "completed"
    }
  ]
}
```

#### `GET /journey/team` (escopo de equipe)

Retorna registros de ponto da equipe (apenas Gestor).

**Permissão exigida:** `journey:view:team` (ou `team:view`).

**Query params:**
- `team_id`: ID do gestor (para determinar "sua" equipe); inferido do JWT se não fornecido.

**Resposta (200 OK):**

```json
{
  "data": [
    {
      "id": "journey-001",
      "user_id": "user-001",
      "user_name": "Colaborador 1",
      "date": "2026-07-01",
      "entry_time": "09:00:00",
      "exit_time": "17:30:00",
      "status": "completed"
    },
    {
      "id": "journey-002",
      "user_id": "user-002",
      "user_name": "Colaborador 2",
      "date": "2026-07-01",
      "entry_time": "08:45:00",
      "exit_time": "17:15:00",
      "status": "completed"
    }
  ]
}
```

**Notas:**
- Só Gestor vê `/journey/team`.
- Backend filtra por `team_id` derivado do JWT (segurança: gestor não pode listar outra equipe).

---

## Seção 5 — Middleware/Padrão de Enforcement de Autorização

### Guard Agnóstico de Autenticação e Autorização

Cada rota precisa de proteção em duas camadas:

1. **Autenticação:** usuário tem um JWT válido?
2. **Autorização:** o JWT pertence a um usuário com a permissão exigida?

### Algoritmo do Guard

**Pseudocódigo:**

```
guard(requiredPermission: String):
  1. Extrair header "Authorization: Bearer <token>"
     Se ausente, retornar 401 UNAUTHORIZED
  
  2. Validar JWT (assinatura, expiração, não está na blacklist)
     Se inválido, retornar 401 UNAUTHORIZED
  
  3. Extrair `sub` (user_id) e `roles` do JWT
  
  4. Resolver permissions efetivas:
     userPermissions = resolvePermissions(sub, roles)
     // Pseudocódigo: query roles -> permissions, com cache
  
  5. Verificar permissão:
     if requiredPermission NOT IN userPermissions:
       retornar 403 FORBIDDEN
     else:
       continuar para handler da rota
```

### Implementação por Framework

O algoritmo acima é agnóstico; cada framework implementa diferente:

**Express.js (Node):**
```javascript
const authGuard = (requiredPermission) => {
  return async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const userPermissions = await resolvePermissions(decoded.sub, decoded.roles);
      
      if (!userPermissions.includes(requiredPermission)) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      
      req.user = { id: decoded.sub, roles: decoded.roles, permissions: userPermissions };
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Invalid token' });
    }
  };
};

app.get('/journey', authGuard('journey:view'), (req, res) => {
  // req.user disponível aqui
});
```

**FastAPI (Python):**
```python
async def auth_guard(required_permission: str):
  def decorator(func):
    @wraps(func)
    async def wrapper(request: Request, *args, **kwargs):
      auth_header = request.headers.get('Authorization')
      if not auth_header:
        return JSONResponse(status_code=401, content={'error': 'Unauthorized'})
      
      token = auth_header.split(' ')[1]
      try:
        decoded = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        user_permissions = await resolve_permissions(decoded['sub'], decoded['roles'])
        
        if required_permission not in user_permissions:
          return JSONResponse(status_code=403, content={'error': 'Forbidden'})
        
        request.user = {'id': decoded['sub'], 'roles': decoded['roles'], ...}
        return await func(request, *args, **kwargs)
      except jwt.InvalidTokenError:
        return JSONResponse(status_code=401, content={'error': 'Invalid token'})
  return decorator

@app.get('/journey')
@auth_guard('journey:view')
async def get_journey(request: Request):
  # request.user disponível
```

### Resolução de Permissions (com cache)

A função `resolvePermissions(user_id, roles)` é chamada a cada request:

**Com Redis (recomendado):**
```
cacheKey = "user_permissions:{user_id}"
cached = redis.get(cacheKey)
if cached:
  return JSON.parse(cached)

permissions = query("SELECT DISTINCT...")
redis.set(cacheKey, JSON.stringify(permissions), EX=300)  // TTL 5 min
return permissions
```

**Sem cache externo (in-memory, simples):**
```
permissionsMap = {} // global, sincronizado com banco a cada X minutos
return permissionsMap.get(user_id)
```

### Tratamento de Erros HTTP

| Código | Situação | Exemplo |
|--------|----------|---------|
| `400 Bad Request` | Requisição mal-formada | JWT ausente, token vazio |
| `401 Unauthorized` | Autenticação falhou | Token expirado, inválido, revogado |
| `403 Forbidden` | Autenticação OK, mas sem permissão | Token válido, mas usuário não tem `journey:view` |
| `404 Not Found` | Recurso não existe | Endpoint errado, user não existe |
| `429 Too Many Requests` | Rate limit excedido | Muitas tentativas de login |
| `500 Internal Server Error` | Erro no servidor | Exception não prevista |

---

## Seção 6 — Dados Seed/Iniciais

### Seed de Papéis (Roles)

Roles de sistema (criados na migração inicial, não podem ser deletados):

| id | name | description | is_system |
|----|------|-------------|-----------|
| 1 | `colaborador` | Colaborador de campo; registra ponto pessoal | `true` |
| 2 | `gestor` | Gestor de equipe; aprova/visualiza ponto da equipe | `true` |

Papéis futuros (exemplos não incluídos no seed, mas adicionáveis depois via admin):
- `rh`: recursos humanos; edita registros, gerencia calendários.
- `admin`: administrador; acesso total, gerencia usuários e papéis.

### Seed de Permissões

Baseado em `Resources` × `Actions` (Seção 1 de `rbac.dart` do frontend):

**Resources:** `journey`, `history`, `profile`.  
**Actions:** `view`, `create`, `update`, `delete`.  
**Escopo:** adicionar permissão de escopo para Gestor: `view:team`.

| id | resource | action | description |
|----|----------|--------|-------------|
| 1 | journey | view | Visualizar próprio registro de ponto |
| 2 | journey | create | Registrar ponto (entrada/saída) |
| 3 | journey | update | Editar registro de ponto |
| 4 | journey | delete | Deletar registro de ponto |
| 5 | history | view | Visualizar histórico próprio |
| 6 | history | view:team | Visualizar histórico da equipe |
| 7 | history | create | (Não usado hoje; placeholder) |
| 8 | history | update | Editar/corrigir histórico |
| 9 | history | delete | Deletar histórico |
| 10 | profile | view | Visualizar perfil próprio |
| 11 | profile | update | Editar perfil próprio |
| 12 | profile | delete | Deletar perfil |

### Matriz Padrão: Roles → Permissions

**Colaborador** recebe permissões:
- `journey:view` (vê seu próprio ponto)
- `history:view` (vê seu próprio histórico)
- `profile:view` (vê seu perfil)

(Replicar o `mockUser` atual de `lib/core/mocks/mock_users.dart`.)

**Gestor** recebe permissões:
- Tudo que Colaborador tem (herança: as 3 permissões acima)
- Mais: `history:view:team` (vê histórico da equipe)
- Opcionalmente: `history:update` (pode corrigir registros de equipe)

### SQL Seed Example

```sql
-- Papéis
INSERT INTO roles (id, name, description, is_system) VALUES
  (1, 'colaborador', 'Colaborador de campo', TRUE),
  (2, 'gestor', 'Gestor de equipe', TRUE);

-- Permissões
INSERT INTO permissions (id, resource, action, description) VALUES
  (1, 'journey', 'view', 'Visualizar próprio registro de ponto'),
  (2, 'journey', 'create', 'Registrar ponto'),
  (3, 'journey', 'update', 'Editar registro de ponto'),
  (4, 'journey', 'delete', 'Deletar registro de ponto'),
  (5, 'history', 'view', 'Visualizar histórico próprio'),
  (6, 'history', 'view:team', 'Visualizar histórico da equipe'),
  (7, 'history', 'update', 'Editar histórico'),
  (8, 'history', 'delete', 'Deletar histórico'),
  (9, 'profile', 'view', 'Visualizar perfil próprio'),
  (10, 'profile', 'update', 'Editar perfil próprio'),
  (11, 'profile', 'delete', 'Deletar perfil');

-- Colaborador tem: view (journey, history, profile)
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (1, 1), (1, 5), (1, 9);

-- Gestor tem: Colaborador + view:team (history) + update (history)
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (2, 1), (2, 5), (2, 9),    -- herança de Colaborador
  (2, 6), (2, 7);             -- extras de Gestor
```

### Usuário Inicial (Administrativo)

É recomendável criar um usuário "admin" durante a primeira migração/deploy para bootstrapping:

```sql
INSERT INTO users (id, name, email, password_hash, status) VALUES
  (uuid(), 'Administrador', 'admin@fjtelecom.com', bcrypt_hash('mudeme123'), 'active');

INSERT INTO user_roles (user_id, role_id) VALUES
  (last_inserted_id, 2);  -- admin como Gestor inicialmente (será atualizado manualmente)
```

**Nota:** a senha deve ser gerada aleatoriamente ou comunicada via canal seguro; o admin faz login e troca na primeira vez.

---

## Seção 7 — Considerações de Migração Futura

### Adicionar um Novo Papel

**Exemplo:** criar papel "RH" para gerenciar registros de todos os colaboradores.

**Passos (sem deploy de código):**

1. **Seed/Migration:**
   ```sql
   INSERT INTO roles (name, description, is_system) VALUES
     ('rh', 'Departamento de RH', FALSE);
   ```

2. **Atribuir permissões** via `/PUT /roles/rh/permissions`:
   ```json
   {
     "permissionIds": [
       "journey:view", "history:view", "profile:view",
       "history:view:team", "history:update", "history:delete"
     ]
   }
   ```

3. **Atribuir a um usuário** via `PUT /users/{id}/roles`:
   ```json
   {
     "roleIds": ["rh"]
   }
   ```

4. **Pronto:** próximo login deste usuário ou próxima resolução de permissions, ele tem as permissões do RH.

### Adicionar um Novo Resource + Action

**Exemplo:** criar um recurso "settings" (configurações de geofence/wifi) com ação "manage".

**Passos:**

1. **Implementar no código:** criar endpoint `PATCH /settings` que valida `settings:manage`.

2. **Criar a permissão** via migration:
   ```sql
   INSERT INTO permissions (resource, action, description) VALUES
     ('settings', 'manage', 'Gerenciar configurações do sistema');
   ```

3. **Atribuir a papéis** que devem ter acesso (ex.: Admin):
   ```sql
   INSERT INTO role_permissions (role_id, permission_id)
   VALUES (admin_role_id, last_inserted_permission_id);
   ```

4. **No frontend:** quando novas permissões forem retornadas, `can('settings:manage')` funcionará automaticamente (sem mudança de código, pois usa string simples).

### Renovação de Permissões Existentes

**Cenário:** descubrir que um Colaborador **nunca** deveria poder deletar seu próprio registro (`journey:delete`).

**Ação:**
```sql
DELETE FROM role_permissions
WHERE role_id = (SELECT id FROM roles WHERE name = 'colaborador')
  AND permission_id = (SELECT id FROM permissions WHERE resource = 'journey' AND action = 'delete');
```

Próximo login, Colaborador não tem mais essa permissão (cache expira em minutos).

### Política de Versionamento do Contrato JSON

**Cenário:** precisa-se adicionar um campo novo ao resposta de `/me` (ex.: `last_login`).

**Ação:** apenas adicione — é backward-compatible. App antigo que não conhece `last_login` o ignora; app novo que conhece o usa.

**Quebra de contrato (breaking change, requer versionamento):**

Exemplo: renomear `permissions` para `capabilities` na resposta de `/me`. Isso quebra o frontend (que tenta desserializar em `UserModel.fromJson` procurando por `permissions`).

**Se um dia houver breaking change real:**

- Opção A: versionar via header: `GET /me` com header `Accept: application/json; version=2`.
- Opção B: versionar via rota: `GET /v2/me`.
- Opção C: manter duas respostas por X tempo (deprecation period).

(Não é necessário agora; mencionado apenas para futuro.)

### Garantias de Compatibilidade Retroativa

Ao fazer mudanças, **nunca:**
- Remover campos obrigatórios do contrato JSON.
- Renomear campos (criar novos, depreciar antigos).
- Mudar tipo de um campo (ex.: string → int).

**Sempre:**
- Adicionar novos campos (ignorados por clientes antigos).
- Depreciar antigos em paralelo com novos.
- Documentar mudanças em changelog.

---

## Apêndice A — Fluxo de Autenticação (Diagrama de Sequência)

```
App Flutter                  Backend
    |                           |
    |--- POST /auth/login ------>|
    |   { email, password }      |
    |                        [valida credenciais]
    |<--- 200 OK ----------------| 
    |   { accessToken,           |
    |     refreshToken,          |
    |     user: {...} }          |
    |                            |
    | [guarda tokens local]      |
    | [mostra biometria]         |
    |                            |
    | [usuário autoriza bio]     |
    | [acesso concedido]         |
    |                            |
    |--- GET /me (+ JWT) -------->|
    |                        [resolve permissions]
    |<--- 200 OK ----------------| 
    |   { id, name, email,       |
    |     permissions: [...] }   |
    |                            |
    | [renderiza UI com base     |
    |  em permissions]           |
    |                            |
    | (tempo passa, JWT          |
    |  está expirado...)         |
    |                            |
    |--- POST /auth/refresh ----->|
    |   { refreshToken }         |
    |                        [valida refresh]
    |<--- 200 OK ----------------| 
    |   { accessToken,           |
    |     refreshToken (novo) }  |
    |                            |
    | [continua com novo token]  |
    |                            |
    | (usuário tapa "Sair")      |
    |--- POST /auth/logout ------>|
    |   { refreshToken }         |
    |                        [revoga token]
    |<--- 200 OK ----------------| 
    |   { message: "..." }       |
    |                            |
    | [limpa armazenamento local]|
    | [volta para tela de login] |
```

---

## Apêndice B — Matriz de Permissões por Papel (Resumo)

| Permissão | Colaborador | Gestor | RH* | Admin* |
|-----------|:-----------:|:------:|:---:|:------:|
| journey:view | ✓ | ✓ | ✓ | ✓ |
| journey:create | - | - | - | ✓ |
| journey:update | - | - | - | ✓ |
| journey:delete | - | - | - | ✓ |
| history:view | ✓ | ✓ | ✓ | ✓ |
| history:view:team | - | ✓ | ✓ | ✓ |
| history:update | - | ✓ | ✓ | ✓ |
| history:delete | - | - | ✓ | ✓ |
| profile:view | ✓ | ✓ | ✓ | ✓ |
| profile:update | ✓ | ✓ | ✓ | ✓ |
| profile:delete | - | - | - | ✓ |
| roles:view | - | - | - | ✓ |
| roles:create | - | - | - | ✓ |
| roles:update | - | - | - | ✓ |
| roles:delete | - | - | - | ✓ |

_* RH e Admin são papéis futuros; não incluídos no seed inicial, apenas exemplificados._

---

## Apêndice C — Checklist de Implementação

Quando implementar o backend em `jornada/api/`, validar:

- [ ] **Modelo de dados:** 5 tabelas (users, roles, permissions, role_permissions, user_roles) com relacionamentos corretos.
- [ ] **Autenticação:** endpoints `/auth/login`, `/auth/refresh`, `/auth/logout` retornando JWT.
- [ ] **Usuário:** endpoint `GET /me` retornando JSON compatível com `UserModel.fromJson` + campo `id`.
- [ ] **Permissões:** resolução de `roles → permissions` funcionando (com cache).
- [ ] **Guard:** middleware de RBAC validando permissões por rota.
- [ ] **Seed:** papéis "colaborador" e "gestor" criados automaticamente na primeira migração.
- [ ] **Erros:** retornar `401` para auth falho, `403` para auth OK mas sem permissão.
- [ ] **Rate limiting:** proteção contra brute-force em `/auth/login`.
- [ ] **HTTPS:** todo tráfico de autenticação deve ser HTTPS (não HTTP).
- [ ] **CORS:** se frontend e backend em domínios diferentes, configurar CORS corretamente.
- [ ] **Refresh token rotation:** novo `refreshToken` emitido a cada `/auth/refresh`.
- [ ] **Logout:** revogação de `refreshToken` funcionando (blacklist ou statusflag).

---

## Histórico de Mudanças

| Versão | Data | Autor | Mudança |
|--------|------|-------|---------|
| 1.0 | 2026-07-01 | Arquitetura Claude Code | Especificação inicial aprovada |
| 1.1 | 2026-07-06 | Arquitetura Claude Code | Recursos admin serializados no payload de login/me (`"*"` agora = catálogo inteiro); endpoints de revisão de jornadas por usuário (`GET /users`, `GET /users/:id/journeys`, ambos `users:view`) |

---

**Fim da Especificação**
