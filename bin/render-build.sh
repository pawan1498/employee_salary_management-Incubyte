#!/usr/bin/env bash
# Render build script for this API-only Rails app (no asset pipeline).
set -o errexit

bundle install
bundle exec rails db:prepare
