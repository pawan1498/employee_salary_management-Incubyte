# React HR app — frontend notes

Companion to [REQUIREMENTS.md](REQUIREMENTS.md) and [DESIGN.md](DESIGN.md).

The UI is a **Vite + React SPA**. It talks JSON to the Rails API. It must not invent business rules (current salary, totals, FX). If the API does not return it, the screen shows empty/missing—not a client-side guess.

Update this file whenever an API contract used by the UI changes.

## Product

**User:** HR Manager. **No login.**

```text
Insights (home)     → compensation questions
Employees           → search, country, department, pagination
Employee detail     → profile, current pay, history, add salary
```

Do not add employee delete, Excel import, or auth.

## Stack (when we scaffold)

- Vite + React (JavaScript or TypeScript—pick one and keep it)
- One component library (e.g. shadcn or MUI)—not a custom design system
- `fetch` or a thin `api.js` helper. No Redux unless the UI is painful without it
- Env: `VITE_API_URL` (e.g. `http://localhost:3000`)

The browser treats Vite (`localhost:5173`) and Rails (`localhost:3000`) as different sites. `curl` does not. `config/initializers/cors.rb` (`rack-cors`) allows local Vite origins and, in production, `CORS_ORIGINS`. Restart Rails after changing CORS.

## Screens

| Route | Purpose | API ready now? |
|---|---|---|
| `/employees` | Directory: `q`, country, department, page | **Yes** — `GET /api/employees` includes `current_salary` |
| `/employees/:id` | Identity, current pay, history | **Yes** — `GET /api/employees/:id` |
| `/employees/:id` form | Add salary | **Yes** — `POST /api/employees/:id/salary_records` with nested `salary_record` |
| `/` insights | Headcount, totals by currency, by country/department | **Yes** — `GET /api/insights` |

Do not start Insights UI until you can call the endpoint below. List + detail + salary form can start after list/show/POST are documented below.

## API the UI should call (as implemented)

**Filter dropdowns** `GET /api/filters`

Static country and department values for search dropdowns. Include an empty “All” option in the UI; send no query param when All is selected.

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
    ]
  }
}
```

Use the returned strings as `country` and `department` query params on `GET /api/employees` and `GET /api/insights`.

**List** `GET /api/employees`

Query: `q`, `country`, `department`, `page`, `per_page` (default 25, max 100).

```json
{
  "data": [
    {
      "id": 1,
      "employee_number": "E-1001",
      "name": "Grace Hopper",
      "country": "United States",
      "department": "Engineering",
      "role": "Rear Admiral",
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

**Show** `GET /api/employees/:id`

```json
{
  "data": {
    "id": 1,
    "employee_number": "E-1001",
    "name": "Grace Hopper",
    "country": "United States",
    "department": "Engineering",
    "role": "Rear Admiral",
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

**Create salary** `POST /api/employees/:id/salary_records`

Body (form or JSON):

```json
{
  "salary_record": {
    "amount": "52000",
    "currency": "USD",
    "effective_date": "2026-01-15"
  }
}
```

- `201` → `{ "data": { "id", "amount", "currency", "effective_date" } }`
- `422` → `{ "errors": ["..."] }` (show next to the form)
- `404` → employee missing

Currency: 3-letter **uppercase** ISO (e.g. `USD`). Amount must be **> 0**. After success, reload show (or append locally only if the API later returns history).

**Insights** `GET /api/insights`

Query (optional, same as the directory): `country`, `department`.

Uses each employee's **current** salary only. Never sums mixed currencies into one number. Money fields are decimal strings. Headcount is the employee count for the filter (people without a salary are counted there but omitted from money breakdowns).

```json
{
  "data": {
    "headcount": 3,
    "by_currency": [
      { "currency": "USD", "headcount": 2, "total": "150000.0", "average": "75000.0" }
    ],
    "by_country": [
      { "country": "United States", "currency": "USD", "headcount": 2, "total": "150000.0", "average": "75000.0" }
    ],
    "by_department": [
      { "department": "Engineering", "currency": "USD", "headcount": 2, "total": "150000.0", "average": "75000.0" }
    ],
    "distribution": [
      { "currency": "USD", "bucket": "0-49999", "headcount": 1 },
      { "currency": "USD", "bucket": "50000-99999", "headcount": 1 },
      { "currency": "USD", "bucket": "100000-149999", "headcount": 1 },
      { "currency": "USD", "bucket": "150000+", "headcount": 1 }
    ]
  }
}
```

Amount buckets (native currency, not converted): `0-49999`, `50000-99999`, `100000-149999`, `150000+`.

## UX bar

- Loading, empty (“No employees match”), and error states
- Paginate; never fetch 10k rows
- Disable submit while POST is in flight
- Show 422 messages from `errors`
- Simple table + one form—not dashboard kits

## Out of scope for the SPA

Login, routing guards, FX conversion, mixing currencies into one “total pay”, optimistic overwrite of salary history, Next.js.

## Build order (UI)

1. Vite app + `VITE_API_URL` + CORS  
2. Employee list (search, filters, pagination)  
3. Employee detail (identity)  
4. Add-salary form (POST)  
5. Display `current_salary` / `salary_history` from list and show  
6. Insights page after `GET /api/insights`

## Maintenance

When a request spec changes the JSON shape, update **this file in the same commit** (or the immediately following `docs:` commit) so reviewers and the React app stay aligned.
