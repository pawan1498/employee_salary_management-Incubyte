# AI-assisted development workflow

Companion to [REQUIREMENTS.md](REQUIREMENTS.md) and [DESIGN.md](DESIGN.md).

This document explains **how I used agentic AI (Cursor) on this take-home** — what I owned, what AI accelerated, and how quality was kept high. Incubyte requires AI use; they also care that engineering judgment stays with the human.

## Tools

| Tool | Role |
|---|---|
| **Cursor (Agent mode)** | Primary coding assistant — specs, implementation, refactors, deploy scripts, docs |
| **Cursor rules** (`.cursor/rules/rails-engineering.mdc`) | Persistent instructions: TDD order, API contract, “Rails first”, no invented scope, CI bar before commit |
| **GitHub Actions** | Objective gate — RuboCop, Brakeman, bundler-audit, RSpec on every push |

Frontend work used the same Cursor setup in a **separate repo** (`employee_salary_management-frontend-Incubyte`).

## What I owned (human decisions)

These were written or approved **before** asking AI to implement:

1. **Product scope** — [REQUIREMENTS.md](REQUIREMENTS.md): must-haves vs should-haves, no auth/payroll, append-only salary history, reporting currency for insights.
2. **Architecture** — [DESIGN.md](DESIGN.md): Rails JSON API + thin React SPA, SQLite locally, Postgres on Render, TDD slice order.
3. **API contract** — endpoint shapes, pagination, error codes; kept in sync with request specs and [FRONTEND.md](FRONTEND.md).
4. **Commit boundaries** — AI proposed messages; **I ran every commit** so history reflects deliberate slices (~41 backend commits, ~38 frontend).
5. **Review** — I read diffs, ran the full CI-equivalent suite locally, and rejected or corrected AI output when it over-engineered or drifted from the contract.

## What AI accelerated

Typical loop for each feature slice:

```text
Me: define behaviour (often already in DESIGN.md)
  → AI: write failing request spec
  → Me: review example names and assertions
  → AI: minimum implementation to go green
  → Me: run bundle exec rspec + rubocop
  → AI: refactor if duplication appeared
  → Me: commit (test:/feat:/refactor:/docs:)
```

Concrete areas where AI saved the most time **without** replacing judgment:

| Area | AI helped with | I verified |
|---|---|---|
| **Bootstrap** | Rails 8 API init, RSpec setup, CI workflow | Ruby version, gem choices, green first commit |
| **Employee API** | Request specs + paginated index, filters, show | Pagination caps, N+1 avoidance, JSON shape |
| **Salary records** | Append-only create, validations, history on show | DB constraints match model validations |
| **Insights** | SQL aggregations, window function for current salary | No Ruby loops over 10k rows; median correctness |
| **FX layer** | Frankfurter fetcher, cache, WebMock stubs | Rates are indicative; 503 when cache empty |
| **Seeding** | `EmployeeSeeder` batched inserts, idempotency | Exactly 10,000 employees; realistic distribution |
| **Deploy** | Render build/start scripts, CORS, status page | Live seed on Postgres; health check passes |
| **Docs** | FRONTEND.md, README troubleshooting | Docs match actual API responses |

## Rules I gave the AI (summary)

The Cursor rule file encodes non-negotiables. In practice I repeatedly enforced:

- **Outside-in TDD** — request spec first; model spec only for domain rules.
- **No invented requirements** — if unsure, update REQUIREMENTS.md first.
- **Rails is the product** — React renders API data; no client-side salary math for insights.
- **Simple over clever** — no Redis, jobs, or service layers until a controller is hard to read.
- **CI-green commits** — full RuboCop + RSpec before proposing a commit message.
- **Agent never commits** — keeps bisectable history under my control.

## Example prompts (representative)

Not exhaustive — patterns I reused:

- *“Write a failing request spec for GET /api/employees with pagination meta. Follow existing spec style. One behaviour per example.”*
- *“Implement the minimum Rails code to make this spec pass. No new gems. Strong params. Default per_page 25, cap 100.”*
- *“Insights must aggregate in SQL for 10k employees. Use CurrentSalaryRecordsQuery. Convert to base_currency via cached exchange_rates.”*
- *“Review this diff as a senior Rails engineer. Flag N+1, missing DB constraints, and over-abstraction. Do not rewrite.”*

## What I rejected or sent back

AI output was useful but not trusted blindly. Common corrections:

- **Over-abstraction** — generic `EmployeeService` / repository layers → kept logic in models, one query object, a few focused service classes.
- **Scope creep** — auth, delete employee, CSV export → deferred per REQUIREMENTS.md should-haves.
- **Weak tests** — examples named `"works"` or `"index"` → renamed to HR-visible behaviour.
- **Frontend business logic** — computing totals in React → moved to API; UI only displays JSON.
- **Style / CI** — RuboCop spacing, Brakeman warnings → fixed before commit, not “later”.

## Evidence in the repo

Reviewers can trace the workflow in Git:

1. `docs: capture product scope` → `docs: record architecture and TDD plan` **before** feature code.
2. `test: Added first request spec for employee listing (failing test)` → `feat: implement paginated employee list API`.
3. Later slices follow the same pattern (salary records, insights, FX, seed, deploy).
4. Refactors come **after** green tests (`perf: use window function`, `refactor: unify currency list`).

## Test suite as AI guardrail

**71 RSpec examples**, ~0.35s — fast enough to run after every AI edit. Request specs are the API contract; model/service specs cover validations, current-salary selection, FX cache, and seeder idempotency. If AI broke behaviour, the suite failed locally before any commit.

## Honest assessment

AI **roughly halved** boilerplate and exploration time (migrations, spec scaffolding, Render scripts, chart components). It did **not** replace:

- scoping the product,
- choosing append-only salaries and Frankfurter FX,
- reviewing SQL and commit granularity,
- or deciding what to leave out.

That split — **human owns requirements and review, AI accelerates execution** — is what I would repeat on a real team.
