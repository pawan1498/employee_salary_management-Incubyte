# Design notes

Companion to [REQUIREMENTS.md](REQUIREMENTS.md). This is how we will build the contract—not extra product scope.

## User flow (v1)

```text
HR Manager (no login)
    → Insights (compensation overview)
    → Employee list (search, filters, pagination)
    → Employee detail (profile, current salary, history)
    → New salary record (amount, currency, effective date; previous rows kept)
```

Dashboard and “reports” are **one Insights page**. CSV export, top earners, and create-employee are should-haves after must-haves.

## Architecture

Conventional Rails API + a separate **React (Vite) SPA**. Not Next.js: no SSR is required for an internal HR tool talking to JSON.

```text
React (HR UI)
    → JSON HTTP
Rails API (controllers)
    → models / Active Record (SQL aggregations for insights)
    → SQLite (Postgres-compatible schema; SQLite is enough for 10k)
```

No service/query objects until a controller or model is hard to read. No Redis, jobs, or search engine.

## Data model

**employees**

| Column | Notes |
|---|---|
| employee_number | unique, required |
| name | required |
| country | required |
| department | required |
| role | job title; required |

**salary_records**

| Column | Notes |
|---|---|
| employee_id | FK, required |
| amount | decimal, > 0 |
| currency | ISO 4217, required |
| effective_date | required |

Current salary = the row with the latest `effective_date` for that employee; if tied, latest `id`. Updates **insert** a new row.

**Indexes:** unique `employee_number`; `country`; `department`; `(employee_id, effective_date)`.

**Integrity:** NOT NULL, FK, unique employee number. Amount/currency also validated in the model for API errors.

## HTTP API (planned)

Prefix: `/api`. JSON.

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/employees` | Paginated list. Query: `q`, `country`, `department`, `page`, `per_page`. Each row includes current salary when present. |
| GET | `/api/employees/:id` | Identity + current salary + salary history (newest first). |
| POST | `/api/employees/:id/salary_records` | Append a salary. Body: `amount`, `currency`, `effective_date`. |
| GET | `/api/insights` | Headcount; totals/averages **by currency**; breakdown by country and department (currency on each row); distribution buckets per currency. |

Errors: 404 missing employee; 422 validation. Lists: `{ data, meta: { page, per_page, total } }`.

Insights **never** sum mixed currencies into one number.

## TDD order

Outside-in: request spec first, then minimum implementation, then model spec only for domain rules.

1. Paginated employee list
2. Search and country/department filters
3. Show employee + current salary
4. Append-only salary update + invalid input
5. Insights aggregations (SQL, not Ruby loops)
6. Seed 10,000 employees
7. React: insights, list, detail + update form

Each slice should be one or two commits (`test:` then `feat:`).

## Frontend

Vite + React. See **[FRONTEND.md](FRONTEND.md)** for screens, env, and the JSON the SPA may call. Keep that file in sync with request specs.

## Performance (10k)

- Paginate the list; do not return 10k rows.
- `includes` / subquery for current salary so the list is not N+1.
- Insights: `GROUP BY` in the database.
- Seed with batched inserts.
- Index filter and salary lookup columns.

## Deliberately not in this design

Login/SSO, FX conversion, payroll/tax, Excel import, delete employee, background jobs, Elasticsearch, generic service layers.

## Delivery

Deploy API and UI separately is fine. Seed on the deployed database. Demo video follows the flow above on seeded data.
