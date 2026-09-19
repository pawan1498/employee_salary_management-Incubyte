# ACME Employee Salary Management — Requirements

**Persona:** HR Manager at ACME  
**Problem:** Salary data for ~10,000 employees across countries lives in Excel. That is slow, error-prone, and poor for answering “how do we pay people?”

## Goal

Give the HR Manager a web app to **maintain employee salary data** and **answer compensation questions** (cost, headcount, distribution, comparisons by country and department).

This document is the product contract. Features not listed here are out of scope unless this file is updated first.

**Incubyte guidance (confirmed):** Salary history, reporting metrics, currency handling, employee fields, and optional CSV export are left to product judgment. Payroll, tax, self-service, approval workflows, and advanced access control are **not** required. Decisions below reflect that guidance.

## In scope (must have)

1. **Employee directory** — Paginated list of employees. Search by name or employee number. Filter by country and department (and role if present on the record).
2. **Employee record** — View identity fields plus **current salary** (amount, currency, effective date).
3. **Update salary** — Record a new current salary. Previous salary rows stay as history (append; do not silently overwrite).
4. **Compensation insights** — Headcount; total salary cost and average salary **within a currency or country** (no FX conversion); breakdown **by country** and **by department**; salary distribution (amount buckets) for the filtered set. **Median salary is out of scope** — average plus distribution answer “typical pay” without extra SQL/UI; add later if HR asks for it.
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
| FX conversion / org-wide “total pay in USD” | Countries imply multiple currencies. Converting without a rate source is fiction; summing mixed currencies is misleading. Compare **within country/currency**. |
| Median salary | Average + distribution buckets cover “typical pay” for v1; median adds query/UI cost with little extra insight for HR. |
| Joining date | Useful for tenure analytics; not required for directory, salary update, or the insights above. |
| Bulk Excel import, email, approval workflows | Nice for Excel migration; not needed to prove manage + insights. |
| Delete employee, retroactive payroll recalculation | HR can stop using a record later; we keep history simple. |
| Redis, search engines, jobs, microservices | 10k rows is a pagination/index problem, not a distributed-systems problem. |

## Data (minimum)

- **Employee:** employee number (unique), name, country, department, role/title. **Joining date is out of scope** — not needed to find someone, update pay, or answer compensation questions in v1.
- **Salary record:** amount, ISO currency, effective date; current salary = latest effective record per employee. Currency lives on the salary row (can change if an employee moves country).

Invariants belong in the database (uniqueness, required fields, foreign keys) as well as validations.

## Assumptions

- One HR Manager; no employee-facing access.
- **Currency:** store and report in **native currency** per salary record. Incubyte left FX open; we do **not** convert to a common currency — no rate source, and a single “org total in USD” would be misleading. Compare within country/currency instead.
- Seeded employees exist so HR’s main job is find → understand → update pay.
- “Current salary” is the salary record with the latest `effective_date` (tie-break: latest `id`).
- **Salary history** is included (append-only rows with effective dates) because HR needs to see past changes, not only today’s number.

## Success

On seeded data, the HR Manager can find someone, change their salary, see previous amounts, and answer: how many people, what we spend (per country/currency), and how pay sits by department—without opening Excel.
