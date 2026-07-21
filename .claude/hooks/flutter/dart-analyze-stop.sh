#!/usr/bin/env bash
set -uo pipefail

# Só roda no dev container (onde o SDK Flutter em /opt/flutter existe). No host, pula.
[ -f /.dockerenv ] || [ -f /run/.containerenv ] || exit 0

# Hook mora em .claude/hooks/flutter/; o app Flutter fica em app/ (raiz + app/).
cd "$(dirname "${BASH_SOURCE[0]}")/../../../app" || exit 0

stop_active="$(jq -r '.stop_hook_active // false' 2>/dev/null)"

# .dart alterados ou novos vs. HEAD (ACM + untracked sempre existem em disco).
# --relative: caminhos relativos a app/ (o cwd), senão `git diff` os daria a
# partir da raiz do monorepo (app/lib/…) e o `dart analyze` não os acharia aqui.
mapfile -t files < <(
  {
    git diff --name-only --relative --diff-filter=ACM HEAD -- '*.dart'
    git ls-files --others --exclude-standard -- '*.dart'
  } 2>/dev/null | sort -u
)
[ "${#files[@]}" -eq 0 ] && exit 0

# `dart analyze` (não `flutter analyze` cru: falha no pub get por patch do SDK —
# ver AGENTS.md). --fatal-infos torna lints de estilo bloqueantes também.
report="$(dart analyze --fatal-infos "${files[@]}" 2>&1)" && exit 0

# Falhou. 1ª rodada bloqueia pra corrigir; 2ª rodada só avisa (anti-loop).
trimmed="$(printf '%s' "$report" | tail -c 4000)"
if [ "$stop_active" = "true" ]; then
  printf '%s' "$trimmed" | jq -Rs \
    '{systemMessage: ("⚠️ dart analyze ainda com issues:\n" + .)}'
else
  printf '%s' "$trimmed" | jq -Rs \
    '{decision:"block", reason: ("dart analyze encontrou issues nos .dart alterados. Corrija antes de finalizar:\n\n" + .)}'
fi
