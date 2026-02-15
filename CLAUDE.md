# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fully automated stock market data pipeline project with three main components:
- **Ingestion** (`ingestion/`): dlt (data load tool) pipelines fetching stock data from yfinance API to BigQuery
- **Transformation** (`transformation/`): dbt project transforming raw stock data into analytics-ready models
- **Orchestration** (`.github/workflows/`, `orchestration/`): GitHub Actions automating daily pipeline execution

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

# Test specific model
dbt test --select int_moving_averages

# Generate and serve docs
dbt docs generate
dbt docs serve

# Install/update dbt packages
dbt deps
```

## Live Documentation

**Published on GitHub Pages (auto-updated daily):**
- 🔗 **[dbt Docs](https://briza5.github.io/Signiture_project/)** - Interactive data model documentation, DAG lineage, column-level metadata
- 🔗 **[Elementary Report](https://briza5.github.io/Signiture_project/elementary.html)** - Data quality monitoring, test results, anomaly detection

**Local preview:**
```bash
# dbt docs (from transformation/ directory)
dbt docs generate
dbt docs serve  # Opens browser at http://localhost:8080

# Elementary report (from transformation/ directory)
edr report --profiles-dir .  # Generates transformation/edr_target/elementary_report.html
```

### Elementary Data Observability (from `transformation/` directory)
```bash
# Generate Elementary data quality report
edr report --profiles-dir .

# Run Elementary models (creates monitoring tables)
dbt run --select elementary

# Run tests and populate Elementary test results
dbt test
```

## Architecture

### Data Flow
```
GitHub Actions (cron: 8:00 UTC weekdays)
    ↓
yfinance API → dlt pipeline → BigQuery (stocks_raw)
    ↓
dbt staging → dbt intermediate → dbt marts
    ↓                              ↓
    ↓                          Elementary (data quality monitoring)
    ↓
Looker Studio (future)
```

### Ingestion Layer
- **Pipeline**: `stock_pipeline.py` fetches daily stock prices, company metadata, and pipeline run logs
- **Stock Symbols**: Defined in `TEST_SYMBOLS` constant (currently 13 symbols: AAPL, MSFT, GOOGL, etc.)
- **Incremental Strategy**: dlt incremental loading with merge strategy for `daily_prices` (composite key: symbol + date)
- **Initial Load**: Fetches 730 days (2 years) of historical data on first run
- **Company Metadata**: Full replace each run (not incremental)
- **Logging**: Pipeline creates timestamped log files in `../logs/` directory
- **Run Tracking**: Each run gets unique run_id (UUID first 8 chars) tracked in `pipeline_runs` table

### dbt Model Layers
- **Sources** (`models/staging/__sources.yml`): Raw tables from `stocks_raw` dataset
  - `daily_prices`: OHLCV data with symbol and date
  - `company_metadata`: Company information (name, sector, industry, market cap)
  - `pipeline_runs`: Pipeline execution metadata for monitoring

- **Staging** (`models/staging/`): Views with standardized naming and typing, prefixed with `stg_`
  - `stg_daily_prices`: Cleaned OHLCV data
  - `stg_company_metadata`: Standardized company information
  - `stg_pipeline_runs`: Cleaned pipeline run logs

- **Intermediate** (`models/intermediate/`): Business logic and feature engineering, prefixed with `int_`
  - `int_price_calculations`: Daily returns, intraday changes, price ranges, typical prices
  - `int_moving_averages`: 20/50/200-day MAs, trend signals, golden/death crosses
  - `int_volatility_metrics`: Rolling volatility (20/50-day), annualized volatility, volatility regime classification
  - All materialized as views in `intermediate` schema

- **Marts** (`models/marts/`): Materialized tables for analytics
  - `dim_companies`: Company dimension (SCD Type 1) with surrogate keys
  - `dim_sectors`: Sector dimension with industry count aggregation
  - `fct_daily_stock_performance`: Comprehensive fact table joining all intermediate models (OHLCV, returns, MAs, volatility)

### Key dbt Macros
- `calculate_return(current_value, previous_value)`: Calculates percentage returns using SAFE_DIVIDE, rounds to 4 decimals
- `cents_to_dollars(column_name)`: Multi-database macro for currency conversion (supports BigQuery, Postgres, Fabric)

### Window Functions & Analytical Patterns
- **LAG Functions**: Used extensively for previous values (e.g., prev_close_price for daily returns)
- **Partitioning**: All window functions partition by `stock_symbol` and order by `price_date`
- **Moving Averages**: Calculated using AVG() OVER with ROWS BETWEEN window frames
- **Volatility**: Uses STDDEV_POP() over rolling windows for consistency

### Data Quality & Monitoring (Elementary)
- **Elementary Package** (`dbt_packages/elementary`): Data observability and quality monitoring
  - **Test Results Tracking**: Automatically captures dbt test results in BigQuery
  - **Anomaly Detection**: Monitors data quality metrics and detects anomalies
  - **Schema Change Tracking**: Tracks schema evolution over time
  - **Data Freshness**: Monitors pipeline execution timestamps
  - **HTML Reports**: Generate interactive data quality reports with `edr report`
  - **Dataset**: `stocks_dev_elementary` (all Elementary tables)

- **BigQuery Timestamp Fix** (`macros/bigquery_timestamp_fix.sql`):
  - **Problem**: Elementary uses default `timestamp` type which BigQuery interpreted as nanosecond precision
  - **Error**: `Invalid timestamp: '2026-02-14T19:43:26.693945100Z'` (9 digits vs 6 supported)
  - **Solution**: Custom macro `bigquery__edr_type_timestamp()` overrides Elementary's default to use `TIMESTAMP` (microsecond precision)
  - **How it works**: dbt's adapter dispatch mechanism automatically uses BigQuery-specific macro implementation

### Orchestration Layer
- **GitHub Actions** (`.github/workflows/stocks-pipeline.yml`): Automated daily pipeline execution
  - **Schedule**: Cron every weekday 8:00 AM UTC (after US market close)
  - **Manual trigger**: workflow_dispatch with full_refresh option
  - **Jobs**:
    1. `ingest-data`: Runs dlt pipeline (yfinance → BigQuery)
    2. `transform-data`: Runs dbt build + generates docs (staging → intermediate → marts)
    3. `deploy-docs`: Publishes dbt docs + Elementary report to GitHub Pages
    4. `notify`: Checks status and creates execution summary with documentation links
  - **Credentials**: Uses `GOOGLE_APPLICATION_CREDENTIALS` environment variable
  - **Artifacts**: Uploads pipeline logs and documentation (30-day retention)
  - **GitHub Pages**: Auto-published at https://briza5.github.io/Signiture_project/
- **Documentation**:
  - Setup: `orchestration/github-actions/setup.md`
  - GitHub Pages: `orchestration/github-actions/github-pages.md`

## Configuration

### dbt Profiles & Schema Configuration
**Profile `stocks_transformation`** (`transformation/profiles.yml`):
- **Base schema**: `stocks_dev` (dev target)
- **Authentication**: Service account key file
- **Custom schemas** (defined in `dbt_project.yml`):
  - `staging` → `stocks_dev_staging`
  - `intermediate` → `stocks_dev_intermediate`
  - `marts` → `stocks_dev_marts`

**Profile `elementary`** (for `edr` CLI tool):
- **Schema**: `stocks_dev_elementary` (must match where dbt creates Elementary tables)
- **Authentication**: Same service account as stocks_transformation
- **Important**: Elementary models run with `stocks_transformation` profile during `dbt run`, but `edr report` uses `elementary` profile to read results

### dlt Configuration
- Dataset: `stocks_raw` in BigQuery
- Pipeline name: `stocks_pipeline`
- Secrets in `ingestion/.dlt/secrets.toml` (not committed, contains BigQuery credentials)
- Config in `ingestion/.dlt/config.toml` (log level, telemetry settings)

### Stock Symbols List
Current symbols tracked (defined in `stock_pipeline.py`):
- Tech: AAPL, MSFT, GOOGL, AMZN, AMD, NFLX, INTC, PLTR, SNOW
- Media: DIS
- Pharma: BMY
- SaaS: CRM
- REIT: O

## Dependencies

Main dependencies (see `requirements.txt`):
- dlt[bigquery]>=1.20.0
- pandas
- yfinance
- sqlalchemy>=2.0.0

dbt packages (installed via `dbt deps`):
- dbt_utils (>=1.3.0)
- codegen (0.14.0)
- elementary-data/elementary (0.22.0) - Data observability and monitoring

## Development Notes

### Adding New Stocks
Update `TEST_SYMBOLS` list in `ingestion/stock_pipeline.py` and run incremental load

### Data Quality Checks
- **dbt Tests**: Generic tests defined in `intermediate.yml` and `marts.yml` ensure data quality
- **Elementary Monitoring**: Automatic test result tracking, anomaly detection, schema change monitoring
- **Pipeline Status**: Run status tracked per symbol (success/failed/no_data) in `pipeline_runs` table
- **Error Tracking**: Error messages captured and surfaced in Elementary reports

### Elementary Troubleshooting
**Common Issues:**

1. **"Timestamp precision type parameter is not supported"**
   - **Cause**: BigQuery doesn't support `timestamp(6)` syntax (unlike Athena/Trino)
   - **Fix**: Custom macro `bigquery__edr_type_timestamp()` in `macros/bigquery_timestamp_fix.sql`

2. **"Dataset dwhhbbi:elementary was not found"**
   - **Cause**: Mismatch between where dbt creates tables vs where `edr` looks for them
   - **Fix**: Ensure `elementary` profile schema matches actual dataset name (e.g., `stocks_dev_elementary`)

3. **Elementary models going to wrong dataset**
   - **Cause**: Missing namespace in `dbt_project.yml`
   - **Fix**: Add `elementary:` namespace at same level as `stocks_transformation:` in models config

### Working with Intermediate Models
All intermediate models follow consistent patterns:
1. Reference staging layer with `{{ ref('stg_*') }}`
2. Use CTEs for readability (staging_prices, add_previous_close, calculate_metrics)
3. Partition window functions by stock_symbol
4. Document all calculated columns in YAML schema files
