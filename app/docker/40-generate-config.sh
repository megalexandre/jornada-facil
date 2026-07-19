#!/bin/sh
# Gera config.js em runtime a partir do env API_BASE_URL, para que a MESMA
# imagem Docker sirva ambientes diferentes (Coolify) sem rebuild.
#
# A imagem oficial do nginx roda todo *.sh em /docker-entrypoint.d/ antes de
# subir o nginx, então este script é executado a cada start do container.
set -eu
: "${API_BASE_URL:=http://api.jornadafacil.online}"
cat > /usr/share/nginx/html/config.js <<EOF
window.API_BASE_URL = "${API_BASE_URL}";
EOF
echo "[config] config.js gerado com API_BASE_URL=${API_BASE_URL}"
