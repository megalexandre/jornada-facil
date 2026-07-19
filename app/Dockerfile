# Imagem da versão web do Jornada Fácil.
# O 'flutter build web' roda no runner do GitHub Actions; aqui só empacotamos
# o resultado (build/web) em um nginx enxuto.
FROM nginx:1.27-alpine

# Fallback de SPA (Flutter web / GoRouter com path URLs)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Gera config.js em runtime a partir do env API_BASE_URL (mesma imagem em
# qualquer ambiente, sem rebuild). Roda antes do nginx via /docker-entrypoint.d.
COPY docker/40-generate-config.sh /docker-entrypoint.d/40-generate-config.sh
RUN chmod +x /docker-entrypoint.d/40-generate-config.sh

# Artefato já compilado no runner
COPY build/web /usr/share/nginx/html

EXPOSE 80
