# Cursor AI instructions (Incubyte take-home)

Companion to [AI_WORKFLOW.md](AI_WORKFLOW.md), [REQUIREMENTS.md](REQUIREMENTS.md), and [DESIGN.md](DESIGN.md).

This is the **reviewer-facing copy** of the persistent instructions I gave Cursor during development.

| | |
|---|---|
| **Live file (local dev)** | `.cursor/rules/rails-engineering.mdc` — always applied in Agent mode |
| **In Git** | This document — sanitized excerpt; `.cursor/` stays gitignored |
| **Purpose** | Keep AI output aligned with product scope, TDD, and Rails craftsmanship |

Incubyte asks for *prompts or instructions used with AI tools*. This file is that artifact.

---

## 1. Mission

Build **employee salary management** for an HR Manager at ACME (~10,000 employees) as Incubyte's **Software Craftsperson / RoR-I** take-home.

**Demonstrate:**

- Clear thinking and structured problem solving
- Idiomatic Rails + outside-in TDD
- Production-quality code and meaningful tests
- Small, bisectable commits
- Intentional AI use — **human owns requirements and review**

**The Rails JSON API is the primary craft signal.** React is a thin client. It must not outrun or dictate a weak API.

**Product contract:** [REQUIREMENTS.md](REQUIREMENTS.md) and [DESIGN.md](DESIGN.md). Do not invent endpoints, fields, or business rules.

**Git rule for the agent:** never run `git commit`. Propose a conventional message (`test:` / `feat:` / `fix:` / `docs:` / `refactor:`) for the human to run. Never stage `.cursor/`.

---

## 2. Scope guardrails

### In scope (must have)

1. Paginated employee directory — search, filter by country/department/role
2. Employee detail — identity + **current salary** + **append-only history**
3. Salary update — insert new row; never silently overwrite history
4. Compensation insights — headcount, total/average/median in `base_currency`, breakdowns, distribution buckets
5. Seed **10,000** realistic employees
6. Deployed app + meaningful tests

### Deliberately out of scope

| Left out | Why |
|---|---|
| Auth / SSO / roles | Single HR persona; not required for this assessment |
| Payroll, tax, benefits, attendance, leave | Different products; would explode scope |
| Redis, Elasticsearch, background jobs | 10k rows is a pagination/index problem |
| Delete employee | History complicates deletion; not needed to prove the core loop |
| Generic service layers | Add complexity without demonstrated need |

Should-haves (CSV export, top earners, create employee, filtered insights) only **after** must-haves are done.

---

## 3. Development loop

Every feature slice follows this lifecycle:

```text
Requirements (REQUIREMENTS.md / DESIGN.md)
  → Understand behaviour + acceptance criteria
  → Write failing test (request spec first)
  → Minimum implementation
  → Run focused spec → full suite
  → Refactor
  → CI checks green
  → Human commits
```

**RED → GREEN → REFACTOR → FULL SUITE → COMMIT**

Do not skip from requirement straight to implementation.

### Outside-in TDD order (backend)

1. Paginated employee list
2. Search and filters
3. Show employee + current salary
4. Append-only salary update + invalid input
5. Insights aggregations (SQL, not Ruby loops)
6. FX conversion for insights (`base_currency` + cached Frankfurter rates)
7. Seed 10,000 employees
8. React: insights, list, detail, update form

Each slice = one or two commits (`test:` then `feat:`).

---

## 4. AI collaboration rules

AI **accelerates** engineering; it does **not** replace judgment.

### Human owns

- Product scope and architecture
- API contract and business rules
- Review of every diff
- Commit timing and messages
- Security and performance decisions

### AI helps with

- Scaffolding failing request specs
- Minimum implementation to go green
- Refactors after tests pass
- Deploy scripts, docs, boilerplate

### Prompt discipline

**Good:**

> Write the smallest Rails implementation required to make this failing request spec pass. Do not introduce new abstractions or gems. Follow existing project conventions.

**Bad:**

> Build the entire salary management system.

**Before accepting AI code, verify:**

- Satisfies the actual requirement (not invented behaviour)
- No unnecessary gems, abstractions, or N+1 queries
- DB constraints match validations
- You can explain it in an interview

---

## 5. CI bar (every commit)

A commit is not ready until it would pass GitHub Actions:

```bash
bundle exec rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/rails db:test:prepare && bundle exec rspec
```

**Must be true:**

- Entire RSpec suite green (`0 failures`)
- RuboCop: no offenses
- Brakeman and bundler-audit clean
- `db/schema.rb` matches migrations
- Diff is one coherent slice — no `.cursor/`, no secrets, no debug code

Do **not** commit a failing spec “to show TDD”. Keep red local; commit when green.

---

## 6. Strong Rails API contract

The HTTP JSON API is the product. React only renders what request specs prove.

### HTTP shape

- Namespace: `/api`
- Lists: `{ "data": [...], "meta": { "page", "per_page", "total" } }`
- Status codes: `200` reads, `201` creates, `404` missing, `422` validation
- Never `500` for bad input
- Strong parameters only — never `params.permit!`
- Pagination: default `per_page` 25, cap 100, `page` ≥ 1 — **never dump 10,000 rows**

### Domain invariants

- `SalaryRecord` is **append-only** — updating pay inserts a row
- Current salary = latest `effective_date`, tie-break highest `id` — encoded **once** (`Employee#current_salary_record`, `CurrentSalaryRecordsQuery`)
- Amount is `decimal`; currency is ISO 4217; never sum mixed currencies without conversion
- Validations **and** DB constraints: NOT NULL, unique `employee_number`, FK

### Queries (10k employees)

- List/show: no N+1 for current salary
- Insights: `COUNT` / `SUM` / `AVG` / `GROUP BY` in SQL — loading all employees into Ruby is a defect
- Search: sanitised `LIKE` with binds, never interpolated SQL
- Indexes: unique number, country, department, `(employee_id, effective_date)`

### What “strong” does **not** mean

Not Grape, JSON:API gem, JWT, service objects per table, or Elasticsearch. Strong means **correct invariants, honest HTTP, honest SQL, honest tests**.

---

## 7. Architecture preferences

```text
Controller  →  Model / Query / Service (when justified)  →  Database
```

| Pattern | When to use |
|---|---|
| **Model** | Validations, scopes, small domain methods |
| **Query object** | Complex SQL reused in more than one place (e.g. window function for current salary) |
| **Service class** | Multi-step workflow that does not belong in a controller (e.g. insights aggregation, FX cache, seeder) |
| **Serializer gem** | Only after JSON duplication becomes painful |

**Avoid by default:** generic repositories, command frameworks, CQRS, microservices, `EmployeeService`/`SalaryService` boilerplate.

**Controllers stay thin:** receive request → invoke behaviour → render JSON. No 40-line SQL in controllers.

---

## 8. RSpec standards

Tests must be **fast, deterministic, readable, and behaviour-focused**.

### Naming

| Layer | Convention | Example |
|---|---|---|
| File | Resource + layer | `spec/requests/employees_spec.rb` |
| `describe` | HTTP action | `"GET /api/employees"` |
| `context` | Situation | `"when no employees exist"` |
| `it` | Observable outcome | `"returns an empty list and a total of zero"` |

**Bad:** `"works"`, `"index"`, `"should return 200"`, `"calls Employee.all"`

**Good:** `"finds an employee by employee number"`, `"keeps the previous salary record"`

One example → one outcome. Name HR-visible behaviour, not Ruby methods.

### Test pyramid

```text
Many focused model/domain specs
  + meaningful request specs (primary API contract)
  + small number of high-value UI tests
```

Request specs hit the real HTTP stack and database. Do not stub ActiveRecord to fake green.

---

## 9. Rails coding standards (summary)

- Idiomatic Ruby: `snake_case` methods, `CamelCase` classes, no `for`, no `and`/`or` for control flow
- One class per file; Zeitwerk path matches constant
- No `default_scope`; no callbacks that create salary rows or send mail
- Migrations: `null: false`, `foreign_key: true`, decimal `precision`/`scale`, reversible
- Never `Employee.all` then filter 10k rows in Ruby
- CORS allowlist for React origin; no auth unless REQUIREMENTS.md changes
- Update [FRONTEND.md](FRONTEND.md) when API contract changes

---

## 10. Commit message examples

**Good:**

```text
test: define employee search behaviour
feat: add employee search
test: cover salary filtering by country
feat: add compensation insights
refactor: extract current salary query
perf: use window function for insights current rows
```

**Bad:** `changes`, `update`, `done`, `final`, `fix stuff`, `assignment`

History must stay **bisectable** — every commit builds, tests pass, one coherent change.

---

## 11. How this mapped to the repo

These rules directly shaped what reviewers see:

| Rule | Evidence in codebase |
|---|---|
| Docs before code | `docs: capture product scope` → `docs: record architecture` before features |
| Outside-in TDD | `test: … failing test` → `feat: …` pairs in Git history |
| Append-only salary | `SalaryRecord` + `POST …/salary_records`; history on show |
| SQL insights | `CompensationInsights`, `CurrentSalaryRecordsQuery` (window function) |
| No over-engineering | Three focused services, one query object — no generic layers |
| CI discipline | GitHub Actions + 71 RSpec examples, ~0.35s |
| Thin React | Frontend repo renders API JSON; insights math stays in Rails |

For the full human+AI process narrative, see [AI_WORKFLOW.md](AI_WORKFLOW.md). For design decisions, see [TRADE_OFFS.md](TRADE_OFFS.md).
