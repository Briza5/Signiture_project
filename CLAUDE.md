# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stock market data pipeline project with two main components:
- **Ingestion** (`ingestion/`): dlt (data load tool) pipelines fetching stock data from yfinance API to BigQuery
- **Transformation** (`transformation/`): dbt project transforming raw stock data into analytics-ready models

## Common Commands

### Ingestion Pipeline (from `ingestion/` directory)
```bash
# Run incremental load (loads only new data since last run)
python stock_pipeline.py

# Run full refresh (drops state, reloads all historical data)
python stock_pipeline.py --full-refresh
```

### dbt Transformation (from `transformation/` directory)
```bash
# Build all models (run + test)
dbt build

# Run models only
dbt run

# Run specific model
dbt run --select stg_daily_prices

# Run model and all upstream dependencies
dbt run --select +int_price_calculations

# Run tests
dbt test

# Generate docs
dbt docs generate
dbt docs serve
```

## Architecture

### Data Flow
```
yfinance API -> dlt pipeline -> BigQuery (stocks_raw) -> dbt staging -> dbt intermediate -> dbt marts
```

### Ingestion Layer
- `stock_pipeline.py`: Main pipeline fetching daily stock prices, company metadata, and pipeline run logs
- Uses dlt incremental loading with merge strategy for `daily_prices` (keyed on symbol + date)
- Company metadata uses replace disposition (full refresh each run)
- Pipeline runs tracked in `pipeline_runs` table for monitoring

### dbt Model Layers
- **Sources** (`models/staging/__sources.yml`): Raw tables from `stocks_raw` dataset (daily_prices, company_metadata, pipeline_runs)
- **Staging** (`models/staging/`): Views with column renaming and type casting, prefixed with `stg_`
- **Intermediate** (`models/intermediate/`): Business logic transformations, prefixed with `int_`
- **Marts** (`models/marts/`): Final tables for analytics (materialized as tables)

### Key dbt Macros
- `calculate_return(current_value, previous_value)`: Calculates percentage returns with safe division

## Configuration

### dbt Profile
Profile `stocks_transformation` configured in `transformation/profiles.yml`:
- Target: BigQuery (dataset: `stocks_dev`)
- Authentication: Service account key file

### dlt Configuration
- Secrets in `ingestion/.dlt/secrets.toml` (not committed)
- Config in `ingestion/.dlt/config.toml`

## Dependencies

Main dependencies (see `requirements.txt`):
- dlt[bigquery]>=1.20.0
- pandas
- yfinance
- sqlalchemy>=2.0.0

dbt packages (installed via `dbt deps`):
- dbt_utils
- codegen
