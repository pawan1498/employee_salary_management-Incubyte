#!/usr/bin/env bash
# Render build: install gems only. Migrations run on boot (bin/render-start.sh).
set -o errexit

bundle install
