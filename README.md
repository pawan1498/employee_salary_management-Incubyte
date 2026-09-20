# ACME Employee Salary Management — Backend

Rails JSON API for Incubyte's Software Craftsperson / RoR take-home.

HR Managers use a separate **React (Vite) SPA** to search employees, view salary history, add salary records, and read compensation insights. This repo is the **Rails backend only**.

**Assignment scope (one-page requirements):** [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) · **API notes for the UI:** [docs/FRONTEND.md](docs/FRONTEND.md)

## Live deployment

| Service | URL |
|---|---|
| **API** | https://employee-salary-management-incubyte.onrender.com |
| **Frontend** | https://employee-salary-management-frontend-sdqh.onrender.com |

Open the API root in a browser for a simple status page, or use curl:

```bash
open https://employee-salary-management-incubyte.onrender.com
curl https://employee-salary-management-incubyte.onrender.com/up
curl https://employee-salary-management-incubyte.onrender.com/api/insights
```

---

## Stack

| Layer | Choice |
|---|---|
| Language | Ruby **3.4.5** |
| Framework | Rails **8.1** (API-only) |
| Dev / test DB | SQLite (`storage/*.sqlite3`) |
| Production DB | PostgreSQL (Render) |
| Server | Puma |

---

## Prerequisites

Install before you begin:

- **Ruby 3.4.5** — use [rvm](https://rvm.io/)
- **Bundler** — `gem install bundler`
- **SQLite** — usually pre-installed on macOS; on Ubuntu: `sudo apt-get install libsqlite3-dev`

Check versions:

```bash
ruby -v    # should print 3.4.5
bundle -v
```

---

## Local setup (first time)

From the repo root:

```bash
# 1. Use the correct Ruby (pick the tool you have)
rvm use 3.4.5          # rvm
# rbenv install 3.4.5 && rbenv local 3.4.5   # rbenv

# 2. Install gems and create the SQLite database
bundle install
bin/rails db:prepare

# 3. Seed 10,000 employees (safe to re-run — stops at 10,000)
bin/rails db:seed

# 4. Start the API on http://localhost:3000
bin/rails server
```

**One-liner alternative** (runs setup and starts the server):

```bash
bin/setup
```

To set up without starting the server:

```bash
bin/setup --skip-server
```

### Verify locally

```bash
# Health
curl http://localhost:3000/up

# Compensation overview
curl http://localhost:3000/api/insights

# First page of employees
curl "http://localhost:3000/api/employees?page=1&per_page=5"
```

---

## Seed data

`bin/rails db:seed` calls `EmployeeSeeder`, which:

- Creates **10,000** employees across 5 countries and 5 departments
- Gives each employee a current salary (and some salary history)
- Is **idempotent** — if 10,000 employees already exist, it inserts nothing

To reset and reseed from scratch:

```bash
bin/rails db:reset   # drops, migrates, and seeds
```

---

## API endpoints

All routes are under `/api`. Responses are JSON.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/up` | Health check |
| `GET` | `/api/insights` | Headcount, org total/average/median in `base_currency` (default USD), breakdowns |
| `GET` | `/api/employees` | Paginated list (`q`, `country`, `department`, `role`, `page`, `per_page`) |
| `GET` | `/api/employees/:id` | Employee + current salary + history |
| `POST` | `/api/employees/:id/salary_records` | Append a new salary record |
| `GET` | `/api/filters` | Static filter options for dropdowns |

List shape: `{ "data": [...], "meta": { "page", "per_page", "total" } }`.

See [docs/FRONTEND.md](docs/FRONTEND.md) for full request/response examples.

---

## Running tests & lint (same as CI)

```bash
bundle exec rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/rails db:test:prepare && bundle exec rspec
```

Or run the project CI script:

```bash
bin/ci
```

---

## Working with the React frontend locally

The UI lives in a **separate repo / Render Static Site**. It talks to this API over HTTP.

1. Start this API: `bin/rails server` → `http://localhost:3000`
2. Start the Vite app with `VITE_API_URL=http://localhost:3000`
3. CORS allows `localhost` and `127.0.0.1` on any port in development (see `config/initializers/cors.rb`)

---

## Deploy on Render (PostgreSQL)

This app has **no asset pipeline**. Use the repo scripts (works on Render **free tier**, no Shell required):

| Render setting | Value |
|---|---|
| **Build Command** | `./bin/render-build.sh` |
| **Start Command** | `./bin/render-start.sh` |
| **Health Check Path** | `/up` |

**Environment variables (API web service):**

| Key | Value |
|---|---|
| `RAILS_ENV` | `production` |
| `RACK_ENV` | `production` |
| `DATABASE_URL` | Link Postgres: Postgres service → **Connect** → this web service |
| `SECRET_KEY_BASE` | `bin/rails secret` |
| `RAILS_MASTER_KEY` | `cat config/master.key` |
| `CORS_ORIGINS` | Frontend URL, e.g. `https://employee-salary-management-frontend-sdqh.onrender.com` |

On boot, `./bin/render-start.sh` runs migrations and **idempotent** seeding (`EmployeeSeeder` tops up to 10,000; no duplicates after that).

Set build/start commands and env vars in the **Render dashboard** — they are not duplicated in this repo.

**Frontend:** deploy as a Render Static Site with `VITE_API_URL=https://employee-salary-management-incubyte.onrender.com`. Details in [docs/FRONTEND.md](docs/FRONTEND.md).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Could not find gem` | Run `bundle install` |
| `database does not exist` | Run `bin/rails db:prepare` |
| Empty insights / no employees | Run `bin/rails db:seed` |
| `Missing secret_key_base` on Render | Set `SECRET_KEY_BASE` or `RAILS_MASTER_KEY` in Environment |
| API 500 + Postgres socket error | Set `DATABASE_URL` — link Postgres to the web service |
| Frontend CORS error | Set `CORS_ORIGINS` to the frontend URL and redeploy the API |
| Wrong Ruby version | `rvm use 3.4.5` or install 3.4.5 via rbenv/mise |

---

## Project docs

| File | Contents |
|---|---|
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Product scope and decisions |
| [docs/DESIGN.md](docs/DESIGN.md) | Architecture and data model |
| [docs/FRONTEND.md](docs/FRONTEND.md) | React app flows and JSON contract |
| [docs/AI_WORKFLOW.md](docs/AI_WORKFLOW.md) | How Cursor/AI was used; human vs agent ownership |
| [docs/CURSOR_RULES.md](docs/CURSOR_RULES.md) | Cursor Agent instructions (prompts & guardrails) |
| [docs/TRADE_OFFS.md](docs/TRADE_OFFS.md) | Key design decisions and what was left out |
| [docs/PERFORMANCE.md](docs/PERFORMANCE.md) | Query design, indexes, and measured timings at 10k scale |
