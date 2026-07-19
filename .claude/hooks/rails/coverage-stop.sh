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

# Cobertura cobre código de app: só roda se mudou algo em app/ ou lib/.
changed="$(
  {
    git diff --name-only --diff-filter=ACM HEAD
    git ls-files --others --exclude-standard
  } 2>/dev/null | grep -E '\.rb$' | grep -E '^(app|lib)/'
)"
[ -z "$changed" ] && exit 0

# Banco de teste sempre disponível dentro do dev container — sem check de infra.
# Suíte INTEIRA com o gate de 100% (linha+branch) ligado.
report="$(COVERAGE_ENFORCE=1 RAILS_ENV=test bundle exec rspec --no-color --format progress 2>&1)"
status=$?

[ "$status" -eq 0 ] && exit 0   # verde e 100% -> deixa terminar

# Falhou de verdade (teste vermelho ou cobertura < 100%). Recorta o fim da saída
# do rspec, que já traz "Line/Branch Coverage: N%" e a linha "is below the expected
# minimum". (Não lemos coverage/.last_run.json: o SimpleCov não o atualiza quando o
# minimum_coverage falha, então ele ficaria defasado justamente no caso de falha.)
trimmed="$(printf '%s' "$report" | tail -c 4000)"

if [ "$stop_active" = "true" ]; then
  # 2ª rodada: não bloqueia de novo, só avisa (anti-loop infinito).
  printf '%s' "$trimmed" | jq -Rs \
    '{systemMessage: ("⚠️ Cobertura ainda abaixo de 100% (ou testes vermelhos):\n" + .)}'
  exit 0
fi

# 1ª rodada: bloqueia e devolve o contexto pro Claude cobrir os fluxos novos.
printf '%s' "$trimmed" | jq -Rs \
  '{decision:"block", reason: ("A suíte falhou ou a cobertura não está em 100% (linha+branch). Escreva os testes que faltam antes de finalizar:\n\n" + .)}'
exit 0
