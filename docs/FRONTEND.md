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

CORS must allow that origin on the Rails API before the SPA is wired.

## Screens

| Route | Purpose | API ready now? |
|---|---|---|
| `/employees` | Directory: `q`, country, department, page | **Yes** — `GET /api/employees` |
| `/employees/:id` | Identity | **Partial** — show has identity only; current salary + history **not** on this payload yet |
| `/employees/:id` form | Add salary | **Yes** — `POST /api/employees/:id/salary_records` with nested `salary_record` |
| `/` insights | Headcount, totals by currency, by country/department | **No** — wait for `GET /api/insights` |

Do not start Insights UI until the insights endpoint exists. List + detail + salary form can start after list/show/POST are documented below.

## API the UI should call (as implemented)

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
      "role": "Rear Admiral"
    }
  ],
  "meta": { "page": 1, "per_page": 25, "total": 10000 }
}
```

List does **not** yet include `current_salary`. Directory can show identity only until the backend adds it.

**Show** `GET /api/employees/:id` → `{ "data": { ...identity } }`. Missing id → **404**.

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
5. After backend adds `current_salary` / `salary_history` on show (and list): display them  
6. Insights page after `GET /api/insights`

## Maintenance

When a request spec changes the JSON shape, update **this file in the same commit** (or the immediately following `docs:` commit) so reviewers and the React app stay aligned.
