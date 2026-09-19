# ACME Employee Salary Management — Requirements

**Context:** This is my **Incubyte take-home assignment** (Software Craftsperson / Ruby on Rails). ACME and the HR Manager are the **given scenario**, not a real client or production product. This one-page doc is the **scope contract for what I chose to build and deliberately leave out**, with reasoning reviewers can discuss in the interview.

**Persona:** HR Manager at ACME
**Problem:** Salary data for ~10,000 employees across countries lives in Excel. That is slow, error-prone, and poor for answering “how do we pay people?”

## Goal

Within the assignment constraints, build software so the HR Manager can **maintain employee salary data** and **answer compensation questions** (cost, headcount, distribution, comparisons by country and department).

Features not listed here are out of scope for **this submission** unless this file is updated first.

**Incubyte guidance (confirmed):** Salary history, reporting metrics, currency handling, employee fields, and optional CSV export are left to my judgment. Payroll, tax, self-service, approval workflows, and advanced access control are **not** required. Decisions below reflect that guidance.

## Scope decisions (Incubyte guidance)

| Topic | We chose | Why |
|---|---|---|
| **Salary history** | Append-only rows with `effective_date` | HR needs to see past pay changes, not only today’s number. Overwriting would lose audit trail. |
| **Reports** | Headcount; org-wide total, average, and median in a chosen **reporting currency**; breakdown by country and department; distribution buckets — all converted to that currency | HR needs one comparable view across countries, not separate currency silos. Median shows typical pay without being skewed by outliers. |
| **Currency** | Native currency on each salary record; insights converted via `base_currency` query param and cached **Frankfurter** (ECB) rates | Stateless API; React stores HR’s last choice in `localStorage`. Rates are indicative, not payroll truth. |
| **Employee fields** | `employee_number`, name, country, department, role; salary on `salary_records` | Enough to find people, update pay, and report. **Joining date omitted** — useful for tenure later, not needed for the assignment flows. |
| **Scope** | Salary management + reporting only | Payroll, tax, benefits, self-service, approval workflows, and auth are different products and would dominate the assessment. |
| **CSV export** | Should-have after must-haves | Useful for HR, not required to prove the core problem. |

## In scope (must have)

1. **Employee directory** — Paginated list of employees. Search by name or employee number. Filter by country and department (and role if present on the record).
2. **Employee record** — View identity fields plus **current salary** (amount, currency, effective date).
3. **Update salary** — Record a new current salary. Previous salary rows stay as history (append; do not silently overwrite).
4. **Compensation insights** — Headcount; org-wide total, average, and median in a **reporting currency** (`base_currency` param, default `USD`); breakdown **by country** and **by department** (converted); salary distribution buckets.
5. **Seed data** — Script that creates **10,000** realistic employees across multiple countries and departments, each with a current salary (and enough history to demonstrate the feature).
6. **Delivery** — Rails backend, relational DB, **React (Vite) UI**, meaningful tests, deployed app, video demo.
**Primary flow:** Insights (or home) → employee list (search/filter) → employee detail → update salary / view history.

## Should have (only if must-haves are done)

- Filter insights by the same country/department as the directory.
- “Top earners” for a filtered slice (same currency).
- Create a new employee with an initial salary (HR still onboards people).
- CSV export of the current filtered list.

## Out of scope (deliberate)

| Left out | Why |
|---|---|
| Login / SSO / roles | Assessment is a single HR-manager tool. Auth is not required and would dominate time without proving the salary problem. Treat as an internal app. |
| Payroll, tax, benefits, attendance, leave, recruitment, performance, self-service | Different products. Would explode scope. |
| Real-time payroll-grade FX | Insights use cached daily ECB rates (Frankfurter). Fine for management reporting; not for payroll or tax. |
| Joining date | Useful for tenure analytics; not required for directory, salary update, or the insights above. |
| Bulk Excel import, email, approval workflows | Nice for Excel migration; not needed to prove manage + insights. |
| Delete employee, retroactive payroll recalculation | HR can stop using a record later; we keep history simple. |
| Redis, search engines, jobs, microservices | 10k rows is a pagination/index problem, not a distributed-systems problem. |

## Data (minimum)

- **Employee:** employee number (unique), name, country, department, role/title. **Joining date is out of scope** — not needed to find someone, update pay, or answer compensation questions in this submission.
- **Salary record:** amount, ISO currency, effective date; current salary = latest effective record per employee. Currency lives on the salary row (can change if an employee moves country).

Invariants belong in the database (uniqueness, required fields, foreign keys) as well as validations.

## Assumptions

- One HR Manager; no employee-facing access.
- **Currency:** each salary record keeps its **native currency**. Insights accept `base_currency` (Frankfurter-supported ISO code, default `USD`); React persists the HR Manager’s last choice in `localStorage`. Rates are cached 24h from Frankfurter (ECB). Totals are **indicative**, not payroll truth.
- Seeded employees exist so HR’s main job is find → understand → update pay.
- “Current salary” is the salary record with the latest `effective_date` (tie-break: latest `id`).
- **Salary history** is included (append-only rows with effective dates) because HR needs to see past changes, not only today’s number.

## Success

On seeded data, the HR Manager can find someone, change their salary, see previous amounts, pick a reporting currency for insights, and answer: how many people, what we spend org-wide (in that currency), and how pay sits by country and department—without opening Excel.
