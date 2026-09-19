#!/usr/bin/env bash
# Render start: migrate, seed (idempotent), then Puma.
# Env vars (DATABASE_URL, SECRET_KEY_BASE, CORS_ORIGINS, etc.) are set in Render dashboard.
set -o errexit

bundle exec rails db:prepare
bundle exec rails db:seed
exec bundle exec puma -C config/puma.rb
