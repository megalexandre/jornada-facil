#!/usr/bin/env bash

set -uo pipefail

# Só roda dentro do dev container, onde o Postgres do compose está sempre no ar.
# No host (sem banco de teste garantido) pula sem bloquear o Stop.
[ -f /.dockerenv ] || [ -f /run/.containerenv ] || exit 0

# Este hook vive em .claude/hooks/rails/ (raiz do monorepo) mas opera na API
# Rails, que fica em api/ — daí o /../../../api (três níveis até a raiz + api/).
API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../api" && pwd)" || exit 0
cd "$API_DIR" || exit 0

input="$(cat)"
stop_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)"

changed="$(
  {
    git diff --name-only --diff-filter=ACM HEAD
    git ls-files --others --exclude-standard
  } 2>/dev/null | grep -E '\.(rb|rake|ru)$' | grep -E '^(app|lib|config|db|spec)/'
)"
[ -z "$changed" ] && exit 0

# Banco de teste sempre disponível dentro do dev container — sem check de infra.
# Roda as request specs.
report="$(RAILS_ENV=test bundle exec rspec spec/requests --no-color --format progress 2>&1)"
status=$?

[ "$status" -eq 0 ] && exit 0   # verde -> deixa terminar

# Falhou. Recorta (o resumo do rspec fica no fim).
trimmed="$(printf '%s' "$report" | tail -c 4000)"

if [ "$stop_active" = "true" ]; then
  # 2ª rodada: não bloqueia de novo, só avisa (anti-loop infinito).
  printf '%s' "$trimmed" | jq -Rs \
    '{systemMessage: ("⚠️ Testes de integração ainda vermelhos:\n" + .)}'
  exit 0
fi

# 1ª rodada: bloqueia e devolve as falhas pro Claude corrigir.
printf '%s' "$trimmed" | jq -Rs \
  '{decision:"block", reason: ("As request specs (testes de integração) falharam. Corrija antes de finalizar a tarefa:\n\n" + .)}'
exit 0
