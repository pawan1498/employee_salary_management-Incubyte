# Performance considerations

Companion to [DESIGN.md](DESIGN.md) and [TRADE_OFFS.md](TRADE_OFFS.md).

This app serves an HR Manager browsing and reporting on **~10,000 employees**. Performance work focused on **avoiding obvious defects** (full-table loads, N+1, Ruby-side aggregation) rather than premature infrastructure (Redis, search engines, background jobs).

**Guiding principle:** complexity is justified only when measured behaviour or requirements demand it.

---

## Scale assumptions

| Dimension | Typical value | Notes |
|---|---|---|
| Employees | 10,000 | Seeded via `EmployeeSeeder`; idempotent cap |
| Salary records | ~13,000 | Most employees have 1 row; ~⅓ have 2 (history demo) |
| List page size | 25 (default), 100 max | Never return all rows |
| Countries / departments | 5 each | Small cardinality for `GROUP BY` |
| Exchange rates | ~30 currencies | Cached 24h; one Frankfurter fetch per day |

---

## Measured behaviour (local, seeded SQLite)

Run on a MacBook with 10,000 employees and 13,335 salary records (`bin/rails runner` + `Benchmark`, Sep 2026):

| Operation | Time | What it exercises |
|---|---|---|
| `GET /api/employees` equivalent (25 rows + current salary) | **~9 ms** | Pagination + `includes(:salary_records)` + in-memory current pick |
| Filtered `Employee.search(...).count` | **~2 ms** | Indexed scan + `LIKE` with sanitised binds |
| `GET /api/insights` equivalent (full org, USD) | **~168 ms** | Window function + FX join + multiple `GROUP BY` + median SQL |

Production on Render (PostgreSQL, cold/warm variance) will differ, but the shape holds: **list is O(page size)**, **insights is O(all employees)** by design.

Full RSpec suite: **71 examples in ~0.35s** — fast enough to run after every change.

---

## Decisions by layer

### 1. Pagination (employee list)

```ruby
# Api::EmployeesController — default 25, cap 100, page ≥ 1
scope.offset((page - 1) * per_page).limit(per_page)
```

- **Why:** Returning 10,000 JSON rows is unusable for HR and wasteful for the server.
- **Trade-off:** `scope.count` for `meta.total` is a second query. Acceptable — `COUNT(*)` on `employees` with optional indexed filters is cheap.

### 2. Current salary on list (avoid N+1)

```ruby
employees = scope.includes(:salary_records).limit(per_page)
# Employee#current_salary_record picks latest from preloaded rows
```

- **Why:** Without `includes`, each row would query salary records separately (classic N+1).
- **Trade-off:** Loads **all** salary rows per employee on the page, then picks current in Ruby. Fine when history depth is small (1–2 rows in seed data). At production scale with long histories, switch to a SQL subquery / join (same pattern as insights) for list rows only.

### 3. Insights — window function for current row

`CurrentSalaryRecordsQuery` uses `ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY effective_date DESC, id DESC)` to pick one current salary per employee in **one SQL pass**.

- **Why:** Loading 13k+ salary rows into Ruby to find “latest per employee” does not scale.
- **Used by:** `CompensationInsights` for org-wide and grouped aggregations.

### 4. Insights — aggregate in SQL, not Ruby

`CompensationInsights` computes total, average, median, country/department breakdowns, and distribution buckets with:

- `SUM`, `AVG`, `COUNT`, `GROUP BY` in the database
- FX conversion via `JOIN exchange_rates` before aggregation
- Median via a nested window query (not `employees.to_a.sort`)

- **Why:** The requirement is org-wide reporting over 10k people. Ruby loops would allocate thousands of objects per request.
- **Trade-off:** Median SQL is harder to read than `array.sort[n/2]` but runs once per insights request, not per employee in Ruby.

### 5. Indexes (schema)

```text
employees:     UNIQUE employee_number; INDEX country; INDEX department
salary_records: INDEX employee_id; INDEX (employee_id, effective_date)
exchange_rates: UNIQUE (base_currency, quote_currency)
```

- **Why:** Match actual API paths — filter by country/department, look up salaries by employee, join rates by currency pair.
- **Not added (yet):** Composite `(country, department)` — only five values each; single-column indexes are enough at this scale.

### 6. Search

```ruby
where("LOWER(name) LIKE :pattern OR LOWER(employee_number) LIKE :pattern OR LOWER(role) LIKE :pattern", ...)
```

- **Why:** `%term%` `LIKE` with binds is sufficient for 10k rows and keeps the API simple.
- **Not used:** Elasticsearch / pg_trgm — would add ops complexity without a demonstrated latency problem.
- **Revisit when:** Search latency grows with headcount or prefix-only search is required.

### 7. Exchange rates — cache, not per-request fetch

`ExchangeRateStore` refreshes Frankfurter rates at most **once per 24 hours**, persists rows in `exchange_rates`, and serves insights from the DB.

- **Why:** Insights already touch every employee; adding an HTTP call to ECB on each request would dominate latency and fail offline.
- **503** only when fetch fails **and** cache is empty.

### 8. Seeding — batched bulk insert

`EmployeeSeeder` uses `insert_all` in batches of **500** (employees + salary rows per batch).

- **Why:** 10,000 individual `create!` calls would be slow on Render boot and local `db:seed`.
- **Idempotent:** Stops at 10,000 — safe to run on every deploy start.

---

## What we deliberately did not add

| Technology | Why not (at 10k scale) |
|---|---|
| Redis | No shared cache requirement; DB + 24h FX cache is enough |
| Background jobs | Insights are synchronous and ~100–200 ms locally |
| Elasticsearch | `LIKE` search on 10k rows is fine |
| Read replicas / sharding | Single Postgres instance handles this workload |
| Materialised views | Premature; insights SQL is acceptable today |

See [TRADE_OFFS.md](TRADE_OFFS.md) for product-level scope decisions.

---

## Request complexity summary

```text
Employee list (paginated)     O(per_page)     — bounded by pagination cap (100)
Employee show (one person)    O(history rows for one employee)
Insights (full org)           O(employees)    — acceptable for HR dashboard at 10k
FX refresh                    O(currencies)   — once per 24h, not per insights row
```

---

## Production notes (Render)

- **Cold start:** Free-tier web services spin down; first request after idle can be slow — unrelated to query design.
- **PostgreSQL:** Same query patterns as SQLite dev; window functions and aggregations behave similarly.
- **Seed on boot:** `EmployeeSeeder` runs idempotently in `bin/render-start.sh` so demo data exists without manual steps.

---

## If headcount grows (e.g. 100k+)

Prioritised next steps — in order:

1. **List current salary** — SQL subquery join instead of loading full history per employee on index.
2. **Insights filters** — scope employees before aggregation (already supported via params; ensures filtered queries stay smaller).
3. **Search** — prefix index or dedicated search if `LIKE '%term%'` degrades.
4. **Caching** — cache full insights response keyed by `(base_currency, country, department)` with short TTL.
5. **Async insights** — only if p95 latency exceeds HR tolerance after the above.

For this assessment, measured local behaviour and query shape show the system handles **10,000 employees** without extra infrastructure.
