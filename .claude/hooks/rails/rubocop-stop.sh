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
mapfile -t files < <(
  {
    git diff --name-only --diff-filter=ACM HEAD -- '*.rb'
    git ls-files --others --exclude-standard -- '*.rb'
  } 2>/dev/null | sort -u
)

existing=()
for f in "${files[@]:-}"; do
  [ -n "$f" ] && [ -f "$f" ] && existing+=("$f")
done
[ "${#existing[@]}" -eq 0 ] && exit 0

bundle exec rubocop -A --force-exclusion "${existing[@]}" >/dev/null 2>&1
report="$(bundle exec rubocop --force-exclusion "${existing[@]}" 2>/dev/null)"
status=$?

[ "$status" -eq 0 ] && exit 0

if [ "$stop_active" = "true" ]; then
  printf '%s' "$report" | jq -Rs \
    '{systemMessage: ("Rubocop ainda com offenses após autocorreção:\n" + .)}'
  exit 0
fi

printf '%s' "$report" | jq -Rs \
  '{decision:"block", reason: ("Rubocop encontrou offenses não-autocorrigíveis nos arquivos .rb alterados. Corrija antes de finalizar a tarefa:\n\n" + .)}'
exit 0
