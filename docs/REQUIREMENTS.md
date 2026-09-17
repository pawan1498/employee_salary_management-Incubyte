# ACME Employee Salary Management — Requirements

**Persona:** HR Manager at ACME  
**Problem:** Salary data for ~10,000 employees across countries lives in Excel. That is slow, error-prone, and poor for answering “how do we pay people?”

## Goal

Give the HR Manager a web app to **maintain employee salary data** and **answer compensation questions** (cost, headcount, distribution, comparisons by country and department).

This document is the product contract. Features not listed here are out of scope unless this file is updated first.

## In scope (must have)

1. **Employee directory** — Paginated list of employees. Search by name or employee number. Filter by country and department (and role if present on the record).
2. **Employee record** — View identity fields plus **current salary** (amount, currency, effective date).
3. **Update salary** — Record a new current salary. Previous salary rows stay as history (append; do not silently overwrite).
4. **Compensation insights** — Headcount; salary totals and averages **within a currency or country** (no FX conversion); breakdown **by country** and **by department**; a simple distribution (e.g. buckets) for the filtered set.
5. **Seed data** — Script that creates **10,000** realistic employees across multiple countries and departments, each with a current salary (and enough history to demonstrate the feature).
6. **Delivery** — Rails backend, relational DB, React or Next.js UI, meaningful tests, deployed app, video demo.

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
| Bulk Excel import, email, approval workflows | Nice for Excel migration; not needed to prove manage + insights. |
| Delete employee, retroactive payroll recalculation | HR can stop using a record later; we keep history simple. |
| Redis, search engines, jobs, microservices | 10k rows is a pagination/index problem, not a distributed-systems problem. |

## Data (minimum)

- **Employee:** employee number (unique), name, country, department, role/title.
- **Salary record:** amount, ISO currency, effective date; current salary = latest effective record per employee.

Invariants belong in the database (uniqueness, required fields, foreign keys) as well as validations.

## Assumptions

- One HR Manager; no employee-facing access.
- Amounts are stored and shown in native currency; insights never mix currencies into one number.
- Seeded employees exist so HR’s main job is find → understand → update pay.
- “Current salary” is the salary record with the latest `effective_date`.

## Success

On seeded data, the HR Manager can find someone, change their salary, see previous amounts, and answer: how many people, what we spend (per country/currency), and how pay sits by department—without opening Excel.
