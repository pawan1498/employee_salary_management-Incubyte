# Trade-offs and design decisions

Companion to [REQUIREMENTS.md](REQUIREMENTS.md) and [DESIGN.md](DESIGN.md).

Incubyte asks for engineering judgment, not the most complex system. These are the main decisions I made, what I traded away, and what I would revisit with more time.

## Architecture

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Backend shape** | Rails 8 JSON API (API-only) | Rails + Hotwire, or Next.js full-stack | JD prefers Rails; SPA keeps UI iteration separate; API is testable with request specs alone |
| **Frontend** | React (Vite) in a **separate repo** | Monorepo, or Next.js | Clear boundary: Rails owns business rules; React is a thin client. Two Render services deploy independently |
| **Local DB** | SQLite | Postgres everywhere | Zero setup for reviewers; schema is Postgres-compatible |
| **Production DB** | PostgreSQL on Render | SQLite on Render | Render free tier + concurrent requests; Postgres is the realistic production default |
| **Auth** | None | Devise / SSO | Single HR Manager persona; auth would dominate the assessment without proving the salary problem |

```text
React SPA  ──JSON──▶  Rails controllers  ──▶  Models / SQL  ──▶  SQLite (dev) / Postgres (prod)
```

## Domain model

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Salary updates** | Append-only `salary_records` with `effective_date` | Update column on `employees` | Preserves history; matches HR audit needs; current = latest row |
| **Current salary rule** | Latest `effective_date`, tie-break highest `id` | “Most recent created_at” | Effective date is the business truth; encoded once in `Employee#current_salary_record` and `CurrentSalaryRecordsQuery` |
| **Employee fields** | number, name, country, department, role | Add joining date, manager, level | Enough for search, filter, and reporting; joining date is a should-have for tenure analytics later |
| **Delete employee** | Not implemented | Soft delete | Out of scope; salary history complicates deletion; HR can stop using a record |

**Integrity:** validations for API errors + DB constraints (NOT NULL, unique `employee_number`, FK, decimal amount). Uniqueness is enforced in **both** places.

## Queries and performance (~10,000 employees)

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Employee list** | Paginate (default 25, cap 100) | Return all rows | 10k JSON rows is unusable and slow |
| **Current salary on list** | Subquery / eager load pattern | N+1 per employee | List must stay O(page size), not O(all employees) |
| **Insights current rows** | `ROW_NUMBER()` window in `CurrentSalaryRecordsQuery` | Load all `SalaryRecord` in Ruby | One SQL pass picks current row per employee at scale |
| **Aggregations** | `GROUP BY`, `SUM`, `AVG`, median in SQL via `CompensationInsights` | Load employees into Ruby | Database work belongs in the database |
| **Indexes** | `employee_number`, `country`, `department`, `(employee_id, effective_date)` | Extra indexes upfront | Match actual filter and salary lookup paths |
| **Search** | Case-insensitive `LIKE` with sanitised binds | Elasticsearch | 10k rows does not justify search infrastructure |

Seeding uses **batched inserts** (`EmployeeSeeder`) and is **idempotent** — safe to re-run on Render boot without duplicating 10,000 rows.

## Currency and insights

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Stored currency** | Native ISO code on each salary record | Normalise everything to USD at write time | Employees can move countries; history stays honest |
| **Reporting currency** | `base_currency` query param (default USD) | Fixed USD only | HR needs one comparable view across countries |
| **FX source** | Frankfurter (ECB), cached 24h in `exchange_rates` | Real-time payroll FX, manual rates | Free, no API key; good enough for **management reporting**, not payroll |
| **Rate storage** | USD hub + quote currencies in DB | Fetch on every insights request | Avoids hammering Frankfurter; 503 only when cache is empty and fetch fails |
| **Currency list** | Single `CurrencyCatalog` | Hard-coded arrays in API and UI | One source of truth for validations, filters, and dropdowns |
| **Median** | Computed in SQL after FX conversion | Average only | Median resists outlier skew; HR gets a “typical pay” signal |

**Explicit limitation:** converted totals are **indicative**. I would not use them for payroll, tax, or legal compliance without a different FX policy.

## Code organisation

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Controllers** | Thin — params, scope, render JSON | Fat controllers with SQL | Readable HTTP layer; behaviour is testable via request specs |
| **Service objects** | Only where justified: `CompensationInsights`, `ExchangeRateStore`, `EmployeeSeeder` | Service per table | Avoid enterprise theatre; extract when complexity is real |
| **Query object** | `CurrentSalaryRecordsQuery` only | None, or many query objects | Window-function SQL was too large to duplicate in controller and insights |
| **Serializers / Grape / JSON:API** | Private controller helpers | Heavy serialization gems | Small API surface; duplication not painful enough yet |

## Testing

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Primary tests** | Request specs (HTTP contract) | Controller specs | End-to-end through routing, params, and DB |
| **Model specs** | Validations, current salary selection, catalog rules | Test every accessor | Domain invariants worth unit isolation |
| **HTTP stubbing** | WebMock for Frankfurter | VCR cassettes | Deterministic FX tests without recorded fixture drift |
| **Factories** | Minimal helpers in specs | FactoryBot everywhere | Small domain; explicit `create!` helpers stay readable |

**71 examples, ~0.35s** — fast enough to run after every change; same bar as GitHub Actions CI.

## Delivery

| Decision | Chosen | Alternative considered | Why |
|---|---|---|---|
| **Hosting** | Render (API + Postgres + static frontend) | Heroku, Fly, single VM | Simple deploy story for assessment; documented in README |
| **Health check** | `/up` + HTML status at `/` | API-only root | Render health checks and quick human verification |
| **CORS** | Allowlist Vite dev origins + `CORS_ORIGINS` in prod | Open `*` | Required for SPA; production origin is explicit |
| **Seed on deploy** | Idempotent `EmployeeSeeder` in start script | Manual seed step | Demo URL always has 10k employees after cold start |

Live: [API](https://employee-salary-management-incubyte.onrender.com) · [Frontend](https://employee-salary-management-frontend-sdqh.onrender.com)

## Deliberately deferred (should-haves)

Documented in REQUIREMENTS.md as **after must-haves**:

- Filter insights by country/department
- Top earners
- Create employee with initial salary
- CSV export

I prioritised a **correct core loop** (find → view → update salary → insights in reporting currency) over breadth. All four are straightforward extensions on the existing API.

## If this were production

With more time and real users, I would revisit:

1. **Authentication and audit** — who changed which salary and when (beyond append-only rows).
2. **FX policy** — dated rates for historical reports, not just “latest cache”.
3. **Insights filters** — same dimensions as the employee directory.
4. **Observability** — structured logging, slow-query alerts on insights.
5. **Monorepo or OpenAPI** — single repo and published schema if frontend and backend teams diverge.

For this assessment, the guiding principle was: **the simplest system that correctly solves the HR Manager’s problem and proves strong Rails craftsmanship.**
