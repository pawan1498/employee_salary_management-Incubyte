# ACME Employee Salary Management

Rails API for Incubyte's Software Craftsperson / RoR take-home.

Product contract: [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)

## Stack

- Ruby **3.4.5**
- Rails 8.1 (API-only)
- SQLite

## Setup

```bash
rvm use 3.4.5
bin/setup
bin/rails server
```

Seed **10,000** employees (batched inserts; skip if already full):

```bash
bin/rails db:seed
```
