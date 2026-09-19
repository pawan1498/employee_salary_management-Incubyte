# React HR app — frontend notes

Companion to [REQUIREMENTS.md](REQUIREMENTS.md) and [DESIGN.md](DESIGN.md).

The UI is a **Vite + React SPA** in a **separate repository** (`employee_salary_management-frontend-Incubyte`). It talks JSON to this Rails API. It must not invent business rules (current salary, totals, FX). If the API does not return it, the screen shows empty/missing—not a client-side guess.

Update this file whenever an API contract used by the UI changes.

## Product

**User:** HR Manager. **No login.**

```text
Insights (home)     → compensation questions in a chosen reporting currency
Employees           → search, country, department, role, pagination
Employee detail     → profile, current pay, history, add salary
```

Do not add employee delete, Excel import, or auth.

## Stack (implemented)

| Layer | Choice |
|---|---|
| Build | Vite |
| UI | React + TypeScript |
| Components | MUI |
| Routing | React Router |
| Data | Native `fetch` via `src/api/api.ts`; local React state only |
| Config | `VITE_API_URL` (e.g. `http://localhost:3000`) |

The browser treats Vite (`localhost:5173`) and Rails (`localhost:3000`) as different sites. `curl` does not. `config/initializers/cors.rb` (`rack-cors`) allows local Vite origins and, in production, `CORS_ORIGINS`. Restart Rails after changing CORS.

### Frontend repo layout (key files)

```text
src/
  api/           api.ts, employees.ts, filters.ts, insights.ts
  hooks/         useFilters.ts
  pages/         InsightsPage, EmployeesPage, EmployeeDetailPage
  types/         employee, filters, insights, salary
  constants/     storage.ts (localStorage key for base currency)
  components/    Layout, FilterBar, Pagination, loading/empty/error states
```

## Local development

**Terminal 1 — Rails API (this repo)**

```bash
bin/rails db:migrate
bin/rails db:seed   # optional; creates 10,000 employees
bin/rails server    # http://localhost:3000
```

**Terminal 2 — React SPA (frontend repo)**

```bash
cp .env.example .env   # VITE_API_URL=http://localhost:3000
npm install
npm run dev            # http://localhost:5173
```

Smoke-test from the shell (no CORS needed):

```bash
curl -s http://localhost:3000/api/filters -H 'Accept: application/json'
curl -s 'http://localhost:3000/api/insights?base_currency=USD' -H 'Accept: application/json'
```

The browser sends `Origin: http://localhost:5173`; the API must include `Access-Control-Allow-Origin` on responses.

## Deploy on Render

**Live URLs**

| Service | URL |
|---|---|
| React UI | https://employee-salary-management-frontend-sdqh.onrender.com |
| Rails API | https://employee-salary-management-incubyte.onrender.com |

```text
React (frontend repo)  →  VITE_API_URL=https://employee-salary-management-incubyte.onrender.com
Rails (this repo)      →  CORS_ORIGINS=https://employee-salary-management-frontend-sdqh.onrender.com
```

To keep local dev working too, comma-separate both origins on the API:

```text
CORS_ORIGINS=http://localhost:5173,https://employee-salary-management-frontend-sdqh.onrender.com
```

**API (this repo; env vars live in Render dashboard)**

- `bin/render-build.sh` — `bundle install`
- `bin/render-start.sh` — `db:prepare`, idempotent `db:seed`, Puma

**UI (frontend repo)**

| Setting | Value |
|---|---|
| Build command | `npm install --include=dev && npm run build` |
| Start command (Web Service) | `npm start` |
| Publish directory (Static Site) | `dist` |
| Env | `VITE_API_URL=https://employee-salary-management-incubyte.onrender.com` |

Add a SPA fallback (`public/_redirects` → `/* /index.html 200`) so `/employees/:id` serves `index.html`.

**Flow after both are live**

1. Run migrations on the API (includes `exchange_rates` table).
2. Set `CORS_ORIGINS` on the API to the Static Site URL (plus localhost if needed).
3. Redeploy API, then UI.
4. Smoke-test: Insights → employee list → detail → add salary.

First insights request after deploy may fetch FX rates from Frankfurter; subsequent requests use the 24-hour cache.

## Screens and routes

| Route | Purpose | API |
|---|---|---|
| `/` | Insights: headcount, total/average, by country/department, salary ranges | `GET /api/filters`, `GET /api/insights` |
| `/employees` | Directory: search, country, department, role, pagination | `GET /api/filters`, `GET /api/employees` |
| `/employees/:id` | Identity, current pay, history, add-salary form | `GET /api/filters`, `GET /api/employees/:id`, `POST …/salary_records` |

Nav: **Insights** (home) and **Employees** in the app bar (`Layout.tsx`).

## Page flows (as implemented)

### Shared: filters bootstrap

1. `useFilters()` calls `GET /api/filters` once on mount.
2. While loading → show loading state; on failure → error state (page cannot render dropdowns).
3. Dropdowns include an empty **All** option; omit the query param when All is selected (`api.ts` skips empty strings).

### Shared: reporting currency picker

Used on **Insights**, **Employees**, and **Employee detail**. Same `localStorage` key (`base_currency`) everywhere.

1. Resolve initial value from `localStorage` or `default_base_currency` in filters.
2. Render a **searchable** reporting currency control (`ReportingCurrencySelect` — MUI Autocomplete).
3. On change → save to `localStorage` and refetch page data that depends on currency.

### Employees (`/employees`)

1. Load filters → render reporting currency picker + search box + country/department/role dropdowns.
2. `GET /api/exchange_rates?base_currency=…` for indicative per-row conversion.
3. Search input is debounced (300 ms) before setting `q` and resetting to page 1.
4. `GET /api/employees?q=&country=&department=&role=&page=1&per_page=25`.
5. Table shows employee number, name, country, department, role, and **current salary in native currency plus an approximate equivalent in the selected reporting currency**.
6. Row links to `/employees/:id`. Pagination uses `meta.page`, `meta.per_page`, `meta.total`.
7. Active filters shown as chips with clear actions.

### Employee detail (`/employees/:id`)

1. Load filters (salary form + reporting currency picker) and `GET /api/employees/:id`.
2. `GET /api/exchange_rates?base_currency=…` for indicative conversion on current salary and history rows.
3. Show identity grid, current salary card (native + reporting approx.), salary history table (newest first).
4. Add-salary form: amount, currency (`currencies` from filters), effective date.
4. Client-side validation (required fields, amount > 0) before POST.
5. `POST /api/employees/:id/salary_records` as **FormData** (`salary_record[amount]`, etc.).
6. On `201` → re-fetch show to update current salary and history.
7. On `422` → show `errors` next to the form. On `404` → not-found state.

### Insights (`/`)

1. Load filters → searchable reporting currency picker from `currencies` (shared with employee pages).
2. `GET /api/insights?base_currency=…&country=&department=` (omit empty filter params).
3. Render stat cards (headcount, total, average, median), `rates_as_of` note, tabbed breakdowns:
   - **By country** — headcount pie chart + table (total/average per country)
   - **By department** — headcount pie chart + table
   - **Salary ranges** — stacked bar chart + table (`distribution` buckets)
4. Country/department filters reuse the same filter bar pattern as employees.
5. Currency change → save to `localStorage` (`base_currency` key), refetch insights.
6. On `503` (FX unavailable) → error state with retry. On `422` (bad currency) → show API errors.
7. Do **not** convert amounts in the browser — the API owns FX math.

## API the UI should call (as implemented)

### Filter dropdowns — `GET /api/filters`

Static country, department, role, and currency lists for dropdowns.

```json
{
  "data": {
    "countries": [
      "United States",
      "United Kingdom",
      "India",
      "Germany",
      "Canada"
    ],
    "departments": [
      "Engineering",
      "People",
      "Finance",
      "Sales",
      "Operations"
    ],
    "roles": [
      "Account Executive",
      "Accountant",
      "Backend Engineer",
      "Engineering Manager",
      "Financial Analyst",
      "HR Generalist",
      "Office Manager",
      "Operations Specialist",
      "Recruiter",
      "Sales Manager",
      "Software Engineer"
    ],
    "currencies": [
      "AUD", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP",
      "HKD", "HUF", "IDR", "ILS", "INR", "ISK", "JPY", "KRW", "MXN", "MYR",
      "NOK", "NZD", "PHP", "PLN", "RON", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"
    ],
    "default_base_currency": "USD"
  }
}
```

| Field | UI use |
|---|---|
| `countries`, `departments`, `roles` | Employee list search filters; insights filters |
| `currencies` | Single Frankfurter-supported list — salary form, reporting picker, and API validation |
| `default_base_currency` | Initial reporting currency when `localStorage` is empty |

One **`currencies`** list (30 Frankfurter ECB codes) drives everything: saving a salary, picking insights base currency, and exchange rates. Codes not in this list (e.g. BGN) return `422`. Seeded employees still use each country's native currency (USD, GBP, INR, EUR, CAD); HR may record salaries in any supported code.

### Exchange rates — `GET /api/exchange_rates`

Query (optional): `base_currency` (Frankfurter ISO code; default `USD`).

Returns cached Frankfurter (ECB) rates for converting salary currencies into the requested reporting currency. Used by employee list/detail for approximate per-row equivalents. Insights aggregation still happens entirely in `GET /api/insights`.

| Status | When |
|---|---|
| `200` | Success |
| `422` | `{ "errors": ["Base currency is not supported"] }` |
| `503` | `{ "errors": ["Exchange rates are temporarily unavailable"] }` |

```json
{
  "data": {
    "base_currency": "USD",
    "rates_as_of": "2026-09-19",
    "rates": {
      "USD": "1.000000",
      "GBP": "0.790000",
      "EUR": "0.920000",
      "INR": "83.500000",
      "CAD": "1.350000"
    }
  }
}
```

Conversion on employee pages: `reporting_amount = native_amount / rates[native_currency]` (same formula as Insights SQL).

### List — `GET /api/employees`

Query: `q`, `country`, `department`, `role`, `page`, `per_page` (default 25, max 100). `q` matches name, employee number, or role (partial match, **case-insensitive** — `priya` and `Priya` return the same results).

```json
{
  "data": [
    {
      "id": 1,
      "employee_number": "E-1001",
      "name": "Grace Hopper",
      "country": "United States",
      "department": "Engineering",
      "role": "Software Engineer",
      "current_salary": {
        "id": 10,
        "amount": "95000.0",
        "currency": "USD",
        "effective_date": "2026-01-15"
      }
    }
  ],
  "meta": { "page": 1, "per_page": 25, "total": 10000 }
}
```

`current_salary` is `null` when the employee has no salary records. List does not include full history.

### Show — `GET /api/employees/:id`

```json
{
  "data": {
    "id": 1,
    "employee_number": "E-1001",
    "name": "Grace Hopper",
    "country": "United States",
    "department": "Engineering",
    "role": "Software Engineer",
    "current_salary": {
      "id": 10,
      "amount": "95000.0",
      "currency": "USD",
      "effective_date": "2026-01-15"
    },
    "salary_history": [
      { "id": 10, "amount": "95000.0", "currency": "USD", "effective_date": "2026-01-15" },
      { "id": 9, "amount": "80000.0", "currency": "USD", "effective_date": "2024-01-01" }
    ]
  }
}
```

Missing id → **404** `{ "errors": ["Not found"] }`. Current salary is the latest `effective_date`, then latest `id`. History is newest first.

### Create salary — `POST /api/employees/:id/salary_records`

Body (JSON or FormData — the UI uses FormData):

```json
{
  "salary_record": {
    "amount": "52000",
    "currency": "USD",
    "effective_date": "2026-01-15"
  }
}
```

| Status | Response |
|---|---|
| `201` | `{ "data": { "id", "amount", "currency", "effective_date" } }` |
| `422` | `{ "errors": ["..."] }` — show next to the form |
| `404` | employee missing |

Currency must be one of **`currencies`** (3-letter uppercase ISO). Amount must be **> 0**. After success, re-fetch show.

### Insights — `GET /api/insights`

Query (optional): `country`, `department`, `base_currency` (Frankfurter ISO code; default `USD`).

Uses each employee's **current** salary only, converted to `base_currency` using cached Frankfurter (ECB) rates (`https://api.frankfurter.dev/v1/latest`). Rates refresh lazily every 24 hours; if Frankfurter is down but a cache exists, stale rates are used.

Money fields are decimal strings with two fractional digits. Headcount is the employee count for the filter (people without a salary are counted there but omitted from money breakdowns). Breakdown rows have **no per-row `currency` field** — all amounts are already in `base_currency`.

| Status | When |
|---|---|
| `200` | Success |
| `422` | `{ "errors": ["Base currency is not supported"] }` |
| `503` | `{ "errors": ["Exchange rates are temporarily unavailable"] }` — no cache and Frankfurter unreachable |

```json
{
  "data": {
    "base_currency": "USD",
    "rates_as_of": "2026-09-19",
    "headcount": 3,
    "total": "151000.00",
    "average": "50333.33",
    "median": "50000.00",
    "by_country": [
      { "country": "United States", "headcount": 2, "total": "150000.00", "average": "75000.00" },
      { "country": "India", "headcount": 1, "total": "1000.00", "average": "1000.00" }
    ],
    "by_department": [
      { "department": "Engineering", "headcount": 3, "total": "151000.00", "average": "50333.33" }
    ],
    "distribution": [
      { "bucket": "0-49999", "headcount": 1 },
      { "bucket": "50000-99999", "headcount": 1 },
      { "bucket": "100000-149999", "headcount": 1 }
    ]
  }
}
```

Salary range buckets (in **base_currency** after conversion): `0-49999`, `50000-99999`, `100000-149999`, `150000+`.

## UX bar

- Loading, empty (“No employees match”), and error states on every page
- Paginate; never fetch 10k rows
- Disable submit while POST is in flight
- Show 422 / 503 messages from `errors` (via `ApiError` in `api.ts`)
- Insights retry on transient FX failure
- Simple tables + one form—not dashboard kits

## Out of scope for the SPA

Login, routing guards, client-side FX for **Insights totals** (server owns aggregation), optimistic overwrite of salary history, Next.js, server-side settings API for default currency (React uses `localStorage` + `default_base_currency` from filters).

## Build order (UI) — done

1. ✅ Vite app + `VITE_API_URL` + CORS
2. ✅ Employee list (search, filters, pagination)
3. ✅ Employee detail (identity)
4. ✅ Add-salary form (POST)
5. ✅ Display `current_salary` / `salary_history` from list and show
6. ✅ Insights page: currency picker (`localStorage` + `base_currency` param) + `GET /api/insights`

## Maintenance

When a request spec changes the JSON shape, update **this file in the same commit** (or the immediately following `docs:` commit) so reviewers and the React app stay aligned. Mirror critical API notes in the frontend repo `README.md` when the SPA contract changes.
