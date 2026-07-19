#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:?defina IMAGE=usuario/repo, ex.: IMAGE=alexandre/jornada-api}"
API_DIR="$(cd "$(dirname "$0")/../api" && pwd)"

TAG="${1:-$(git -C "$API_DIR" rev-parse --short HEAD 2>/dev/null || echo latest)}"

echo ">> Buildando ${IMAGE}:${TAG} (linux/amd64) a partir de ${API_DIR}"
docker build --platform linux/amd64 \
  -t "${IMAGE}:${TAG}" \
  -t "${IMAGE}:latest" \
  "${API_DIR}"

docker push "${IMAGE}:${TAG}"
docker push "${IMAGE}:latest"

