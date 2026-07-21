#!/usr/bin/env bash
set -euo pipefail

cd /workspaces/jornada/api && bundle install
cd /workspaces/jornada && bundle install
cd /workspaces/jornada/app && flutter pub get

