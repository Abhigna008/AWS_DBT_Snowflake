# 🏠 Airbnb Analytics Pipeline — Snowflake · dbt · AWS

An end-to-end data pipeline that takes raw Airbnb listings, bookings, and host data and turns it into clean, analytics-ready tables. Built on **AWS S3** for storage, **Snowflake** as the warehouse, and **dbt** for all transformation logic, using a layered **Medallion Architecture (Bronze → Silver → Gold)**.

---

## What This Project Does

Raw CSV data (listings, bookings, hosts) is loaded into Snowflake and pushed through three progressively cleaner layers:

1. **Bronze** — the raw data lands here almost untouched, just enough to standardize types and structure.
2. **Silver** — data gets validated, cleaned, and enriched (e.g. listings get a price tier, host records get quality metrics).
3. **Gold** — everything is joined into wide, denormalized tables built specifically for reporting and analysis (a One Big Table plus a dimensional fact table).

Alongside this, I built **snapshots** that track how bookings, hosts, and listings change over time (Slowly Changing Dimension Type 2), so I can query what a listing or host looked like at any point in the past, not just the current state.

---

## Architecture

```
Raw CSVs ──▶ AWS S3 ──▶ Snowflake Staging
                              │
                              ▼
                     🥉 BRONZE (raw tables)
                              │
                              ▼
                     🥈 SILVER (cleaned, validated, enriched)
                              │
                              ▼
                     🥇 GOLD (OBT + fact table — analytics ready)

        Snapshots run alongside Silver to capture full history
        of every change to bookings, hosts, and listings.
```

**Stack:** AWS S3 · Snowflake · dbt · SQL / Jinja · Python 3.12+ · Git

---

## Data Layers I Built

**Bronze**
- `bronze_bookings`, `bronze_hosts`, `bronze_listings` — raw booking, host, and listing data pulled straight from staging.

**Silver**
- `silver_bookings` — booking records with validation rules applied
- `silver_hosts` — host profiles enriched with quality metrics
- `silver_listings` — standardized listings, with nightly price bucketed into low/medium/high tiers

**Gold**
- `obt` — a single wide table joining bookings, listings, and hosts together for fast, ready-to-query analysis
- `fact` — a proper dimensional fact table for structured reporting
- Ephemeral models handling intermediate joins that don't need to persist as physical tables

**Snapshots (SCD Type 2)**
- `dim_bookings`, `dim_hosts`, `dim_listings` — every change to these records is tracked with valid-from/valid-to dates, so historical states are always recoverable

---

## Key Things I Implemented

**Incremental models** — Bronze and Silver only process new or changed rows instead of reprocessing the entire dataset every run, which keeps warehouse compute costs down as data grows:
```sql
{{ config(materialized='incremental') }}
{% if is_incremental() %}
    WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})
{% endif %}
```

**A custom macro for price tiering** — instead of repeating the same `CASE` logic in multiple models, I wrote a reusable `tag()` macro:
```sql
{{ tag('CAST(PRICE_PER_NIGHT AS INT)') }} AS PRICE_PER_NIGHT_TAG
```

**Dynamic joins in the Gold layer** — the OBT model loops over a config list with Jinja instead of hand-writing every join, so adding a new source later doesn't mean rewriting the whole model:
```sql
{% set configs = [...] %}
SELECT
{% for config in configs %} ... {% endfor %}
```

**Schema-per-layer separation** — a custom `generate_schema_name` macro automatically routes Bronze, Silver, and Gold models into their own separate Snowflake schemas, so raw data, cleaned data, and analytics tables never mix.

**SCD Type 2 snapshots** — set up so that if a host changes their listing price, or a booking status updates, the old version is preserved with a valid-to date instead of being overwritten.

**Data quality checks** — uniqueness and not-null constraints on primary keys, referential integrity checks across bookings/hosts/listings, and custom rule-based tests (e.g. rejecting negative prices or invalid date ranges) baked directly into the dbt project.

---

## Project Structure

```
airbnb-data-engineering-project/
├── README.md
├── pyproject.toml
├── main.py
│
├── source_data/
│   ├── bookings.csv
│   ├── hosts.csv
│   └── listings.csv
│
├── ddl/
│   ├── ddl.sql
│   └── resources.sql
│
└── airbnb_dbt_project/
    ├── dbt_project.yml
    ├── profiles.example.yml
    │
    ├── models/
    │   ├── sources/sources.yml
    │   ├── bronze/
    │   │   ├── bronze_bookings.sql
    │   │   ├── bronze_hosts.sql
    │   │   └── bronze_listings.sql
    │   ├── silver/
    │   │   ├── silver_bookings.sql
    │   │   ├── silver_hosts.sql
    │   │   └── silver_listings.sql
    │   └── gold/
    │       ├── fact.sql
    │       ├── obt.sql
    │       └── ephemeral/
    │           ├── bookings.sql
    │           ├── hosts.sql
    │           └── listings.sql
    │
    ├── macros/
    │   ├── generate_schema_name.sql
    │   ├── multiply.sql
    │   ├── tag.sql
    │   └── trimmer.sql
    │
    ├── analyses/
    │   ├── explore.sql
    │   ├── if_else.sql
    │   └── loop.sql
    │
    ├── snapshots/
    │   ├── dim_bookings.yml
    │   ├── dim_hosts.yml
    │   └── dim_listings.yml
    │
    ├── tests/
    │   └── source_tests.sql
    │
    └── seeds/
```

---

## How to Run It

```bash
git clone https://github.com/<your-username>/airbnb-data-engineering-project.git
cd airbnb-data-engineering-project

python -m venv .venv
source .venv/bin/activate      # or .venv\Scripts\Activate.ps1 on Windows

pip install -e .
```

Set up `~/.dbt/profiles.yml` with your own Snowflake credentials (never commit this file):
```yaml
airbnb_dbt_project:
  outputs:
    dev:
      type: snowflake
      account: <your-account-identifier>
      user: <your-username>
      password: <your-password>
      role: ACCOUNTADMIN
      database: AIRBNB
      warehouse: COMPUTE_WH
      schema: dbt_schema
      threads: 4
  target: dev
```

Run `ddl/ddl.sql` in Snowflake to create the staging tables, then load the CSVs from `source_data/` into `AIRBNB.STAGING.*`.

From there:
```bash
cd airbnb_dbt_project

dbt debug                      # check the connection works
dbt run                        # build every model
dbt run --select bronze.*      # or just one layer at a time
dbt test                       # run data quality checks
dbt snapshot                   # capture SCD history
dbt build                      # models + tests + snapshots together
```

---

## Why I Built It This Way

I wanted the pipeline to reflect how a real analytics team would actually organize a warehouse — not just one script that dumps everything into a single table. Splitting the pipeline into Bronze/Silver/Gold keeps raw data, cleaned data, and reporting data clearly separated, so debugging a bad number means tracing it back one layer at a time instead of untangling one giant query. Incremental models and snapshots were the two pieces I cared about getting right, since those are what make a pipeline usable on real, growing data rather than a one-time demo.
