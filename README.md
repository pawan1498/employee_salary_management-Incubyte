# ACME Employee Salary Management

Rails API for Incubyte's Software Craftsperson / RoR take-home.

Product contract: [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)

## Stack

- Ruby **3.4.5**
- Rails 8.1 (API-only)
- SQLite (development / test)
- PostgreSQL (production on Render)

## Local setup

```bash
rvm use 3.4.5
bin/setup
bin/rails server
```

Seed **10,000** employees (batched inserts; skip if already full):

```bash
bin/rails db:seed
```

## Deploy on Render (PostgreSQL)

This app is **API-only** — there is no asset pipeline. Render's default Rails build runs `assets:precompile`, which fails here. Use the custom build script instead.

### Option A — Blueprint (recommended)

1. Push this repo to GitHub.
2. In [Render](https://render.com): **New → Blueprint** → connect the repo.
3. Render reads `render.yaml` and creates:
   - PostgreSQL database `acme-salary-db`
   - Web service `acme-salary-api`
4. When prompted, set:
   - `RAILS_MASTER_KEY` — contents of your local `config/master.key`
   - `CORS_ORIGINS` — your React static site URL (set after UI deploy), e.g. `https://your-ui.onrender.com`
5. After the first successful deploy, open **Shell** on the web service and seed:

   ```bash
   bundle exec rails db:seed
   ```

6. Verify: `GET https://<your-api>.onrender.com/up` → 200, then `GET /api/insights`.

### Option B — Manual web service

1. **New → PostgreSQL** — note the internal database URL.
2. **New → Web Service** → connect repo, runtime **Ruby**.
3. Settings:

   | Field | Value |
   |---|---|
   | Build Command | `./bin/render-build.sh` |
   | Start Command | `bundle exec puma -C config/puma.rb` |
   | Health Check Path | `/up` |

4. Environment variables:

   | Key | Value |
   |---|---|
   | `RAILS_ENV` | `production` |
   | `RAILS_MASTER_KEY` | from `config/master.key` |
   | `SECRET_KEY_BASE` | `bin/rails secret` |
   | `DATABASE_URL` | from Render Postgres dashboard |
   | `CORS_ORIGINS` | frontend URL when ready |

5. Deploy → Shell → `bundle exec rails db:seed`.

### React UI (separate Static Site)

Deploy the Vite SPA as a **Static Site** with `VITE_API_URL=https://<your-api>.onrender.com`. See [docs/FRONTEND.md](docs/FRONTEND.md).

After the UI URL exists, set `CORS_ORIGINS` on the API and redeploy.
