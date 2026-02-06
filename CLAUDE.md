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

# Test specific model
dbt test --select int_moving_averages

# Generate and serve docs
dbt docs generate
dbt docs serve

# Install/update dbt packages
dbt deps
```

## Architecture

### Data Flow
```
yfinance API -> dlt pipeline -> BigQuery (stocks_raw) -> dbt staging -> dbt intermediate -> dbt marts
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

- **Marts** (`models/marts/`): Materialized tables for analytics (currently empty, ready for fact/dim tables)

### Key dbt Macros
- `calculate_return(current_value, previous_value)`: Calculates percentage returns using SAFE_DIVIDE, rounds to 4 decimals
- `cents_to_dollars(column_name)`: Multi-database macro for currency conversion (supports BigQuery, Postgres, Fabric)

### Window Functions & Analytical Patterns
- **LAG Functions**: Used extensively for previous values (e.g., prev_close_price for daily returns)
- **Partitioning**: All window functions partition by `stock_symbol` and order by `price_date`
- **Moving Averages**: Calculated using AVG() OVER with ROWS BETWEEN window frames
- **Volatility**: Uses STDDEV_POP() over rolling windows for consistency

## Configuration

### dbt Profile
Profile `stocks_transformation` configured in `transformation/profiles.yml`:
- Target: BigQuery (dataset: `stocks_dev`)
- Authentication: Service account key file
- Staging models materialize as views
- Marts models materialize as tables

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
- dbt_utils
- codegen

## Development Notes

### Adding New Stocks
Update `TEST_SYMBOLS` list in `ingestion/stock_pipeline.py` and run incremental load

### Data Quality Checks
- dbt tests defined in `intermediate.yml` ensure data quality
- Pipeline run status tracked per symbol (success/failed/no_data)
- Error messages captured in `pipeline_runs` table

### Working with Intermediate Models
All intermediate models follow consistent patterns:
1. Reference staging layer with `{{ ref('stg_*') }}`
2. Use CTEs for readability (staging_prices, add_previous_close, calculate_metrics)
3. Partition window functions by stock_symbol
4. Document all calculated columns in YAML schema files
