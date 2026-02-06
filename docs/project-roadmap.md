Stock Portfolio Pipeline - Project Roadmap
Status: ✅ Phase 1 & Phase 2 Complete
Start Date: 2025-12-22
Last Updated: 2026-02-06
Tech Stack: yfinance → dlt → BigQuery → dbt Fusion → Looker Studio

🎯 Current Status
Active Phase: Phase 3 - Orchestration (Ready to start)
Completed Phases: Phase 1 (Ingestion), Phase 2 (Staging, Intermediate, Marts)
Current Task: Plan orchestration strategy (scheduler selection)
Blockers: None
Latest Achievements:

✅ dbt-bigquery connection established
✅ BigQuery Storage API enabled
✅ dbt-codegen package → auto-generated source definitions
✅ Staging layer: 3 models (stg_daily_prices, stg_company_metadata, stg_pipeline_runs)
✅ dbt tests implemented on staging layer
✅ dbt documentation framework ready
✅ Intermediate layer: 3 models COMPLETE
  - int_price_calculations.sql (returns, ranges, typical price)
  - int_moving_averages.sql (MA 20/50/200, golden/death cross, trend signals)
  - int_volatility_metrics.sql (rolling volatility 20/50d, annualized, regime classification)
✅ Custom macros: calculate_return.sql
✅ Marts layer: 3 models COMPLETE
  - dim_companies.sql (company dimension with surrogate keys)
  - dim_sectors.sql (sector dimension with industry aggregation)
  - fct_daily_stock_performance.sql (comprehensive daily metrics fact table)


📚 dbt Fusion vs dbt Core - Key Learnings
dbt Fusion Limitations (Discovered 2025-02-05):

❌ No dbt docs generate/serve - Cannot generate documentation site locally
✅ Full dbt Core feature parity - Macros, tests, packages, refs all work
✅ VS Code native integration - No CLI switching, inline previews
✅ Faster iteration cycles - Compile/run directly in editor
✅ Claude Code extension compatible - Code review & refactoring workflow

Workaround Strategy:

Development: dbt Fusion in VS Code (primary workflow)
Documentation: Switch to dbt Core CLI when lineage needed (dbt docs generate)
Production: Standard dbt Core deployment (no Fusion dependency)

Portfolio Value:

Demonstrates hands-on evaluation of cutting-edge tools
Documents real-world limitations vs marketing promises
Shows adaptability (Fusion for dev, Core for docs/prod)


🔋 Phase 1: Data Ingestion (dlt → BigQuery) ✅ COMPLETE
Setup

 GCP Service Account vytvoren (dwhhbbi-21142b907feb.json)
 BigQuery dataset stocks_raw vytvoren
 Project structure vytvoŘena (ingestion/, transformation/, orchestration/, logs/)
 dlt secrets.toml nakonfigurovan (project_id: dwhhbbi, location: US)
 dlt init stocks_pipeline bigquery
 Validace dlt setup

Pipeline Development

 stocks_pipeline.py - test 5 symbolu (AAPL, MSFT, GOOGL, AMZN, NVDA)
 Resource: daily_prices (OHLCV data, merge mode, PK: symbol+date)
 Resource: company_metadata (sector, industry, replace mode)
 Resource: pipeline_runs (metadata tracking pro monitoring)
 First run test (2 roky historie, ~2500 radku)
 Validace dat v BigQuery
 Incremental loading implementace (pouze nova data od max(date))
 Error handling (retry logic, failed symbols log)
 Logging framework (pipeline runs, row counts do logs/)
 CLI argument: --full-refresh pro production management
 MultiIndex columns handling (yfinance compatibility fix)
 Data type fixes (date vs datetime vs string)
 Rozsireni na S&P 50 symbolu
 Test incremental load (druhy den - overeni ze nacte jen nova data)

Technical Issues Resolved

✅ yfinance MultiIndex columns flatten
✅ dlt incremental cursor data type matching (date objects)
✅ BigQuery credentials configuration (service account JSON)
✅ Pipeline state management (lokalni + BigQuery)
✅ Full refresh strategy (pipeline.drop() + dataset cleanup)
✅ Encoding issues (UTF-8 logging, emoji handling)

Advanced Ingestion

 Schema evolution handling
 Data quality checks v pipeline (nulls, duplicates)
 Metadata tracking enhancements (source versions, API rate limits)


🔄 Phase 2: Transformace (dbt Fusion)
Setup ✅ COMPLETE

 dbt-bigquery instalace a konfigurace
 BigQuery connection v dbt (profiles.yml)
 BigQuery Storage API enabled (service account permissions)
 dbt project init (transformation/stock/)
 dbt-codegen package installation
 Source definitions auto-generated (schema.yml)

Staging Layer ✅ COMPLETE

 stg_daily_prices.sql (cleaning, standardizace)
 stg_company_metadata.sql
 stg_pipeline_runs.sql
 Schema tests (not_null, unique, relationships)
 Documentation (staging.yml with source definitions)

Intermediate Layer ✅ COMPLETE
Architecture:

Intermediate = Business logic & calculations (no surrogate keys)
Materialization: view (default), table if query >10s
Purpose: Reusable components for marts layer

Models:

✅ int_price_calculations.sql - COMPLETE

Daily returns (LAG window function)
Intraday change (close vs open)
Price range % (volatility proxy)
Typical price (H+L+C)/3
Custom macro: calculate_return() (reusable)


✅ int_moving_averages.sql - COMPLETE

MA 20/50/200 day
Golden cross / Death cross signals
MA crossover detection
Trend signal classification (strong_uptrend, uptrend, neutral, downtrend, strong_downtrend)


✅ int_volatility_metrics.sql - COMPLETE

20-day, 50-day rolling std dev
Annualized volatility (std * sqrt(252))
Volatility regime classification (low/normal/elevated/high)
Trading days count for data quality


 int_company_dimension_prep.sql (SCD Type 1 prep for marts) - OPTIONAL/FUTURE
 int_sector_dimension_prep.sql (Sector grouping prep) - OPTIONAL/FUTURE

Macros:

✅ macros/calculate_return.sql - Safe division with ROUND

Tests & Documentation:

✅ intermediate.yml - Model documentation complete
✅ Generic tests (not_null tests on key columns)
✅ All 3 models materialized successfully in BigQuery

Marts Layer ✅ COMPLETE
Architecture:

Marts = Presentation layer with surrogate keys
Materialization: table or incremental
Purpose: BI-ready denormalized tables

Dimensions:

✅ dim_companies.sql (SCD Type 1 dimension) - COMPLETE

Surrogate key: {{ dbt_utils.generate_surrogate_key(['company_symbol']) }}
Grain: One row per company
Columns: company_key, company_symbol, company_name, company_sector, company_industry, company_market_cap, company_country
Tests: unique company_key, not_null constraints


✅ dim_sectors.sql (Sector dimension) - COMPLETE

Surrogate key: {{ dbt_utils.generate_surrogate_key(['company_sector']) }}
Grain: One row per sector
Aggregation: industry_count per sector (GROUP BY implementation)
Tests: unique sector_key, not_null constraints


 dim_date.sql (Date dimension - optional/future)

Facts:

✅ fct_daily_stock_performance.sql (comprehensive daily metrics) - COMPLETE

Joins: int_price_calculations + int_moving_averages + int_volatility_metrics
Foreign keys: company_key → dim_companies, sector_key → dim_sectors
Grain: One row per symbol per date
Surrogate key: {{ dbt_utils.generate_surrogate_key(['stock_symbol', 'price_date']) }}
Includes: OHLCV, returns, moving averages, volatility metrics, trend signals
Tests: unique performance_key, FK relationships validated



Aggregations (Future):

 agg_portfolio_summary.sql (cross-stock aggregace)
 agg_sector_performance.sql (sector level analytics)

dbt Best Practices

 Modular design (jeden model = jedna odpovednost)
 Macros pro reusable logic (MA calculation, returns)
 dbt_utils package usage (surrogate_key, date_spine)
 dbt tests coverage (min 80% models)
 Documentation via yml files (descriptions, tests)
 Lineage tracking (via dbt Core docs when needed)


⚙️ Phase 3: Orchestrace
Scheduler Options Evaluation

 GitHub Actions research (free tier limits)
 Dagster Cloud research (free tier features)
 Apache Airflow evaluation (local setup)
 Astronomer Cosmos research (dbt + Airflow integration)
 GCP Cloud Scheduler + Cloud Run research
 Decision: Vybrany scheduler

Implementation

 dlt pipeline automation (denni 8:00 AM UTC)
 dbt Fusion run trigger (po dlt completion)
 Failure notifications (email/Slack webhook)
 Manual trigger option (dev testing)

Monitoring

 Pipeline run history tracking
 Data freshness checks (stale data alerts)
 Cost monitoring (BigQuery query costs)


📊 Phase 4: Vizualizace
Dashboard Design (Looker Studio)

 Looker Studio pripojeni na BigQuery marts
 Chart 1: Portfolio Performance Over Time (line chart)
 Chart 2: Sector Allocation & Performance (treemap)
 Chart 3: Top Gainers/Losers (bar chart)
 Chart 4: Volatility Heatmap (table + conditional formatting)
 Filters: Date range, symbol selector, sector filter

Advanced Visualizations

 Moving averages crossover signals
 Correlation matrix (stock pairs)
 Sharpe ratio comparison

BI as Code Exploration

 Streamlit dashboard prototype
 Evaluate BI-as-code tools (Evidence.dev, Malloy)
 Compare Looker Studio vs Streamlit trade-offs


🎯 Phase 5: Portfolio Enhancement
Documentation

 README.md (projekt overview, tech stack)
 Architecture diagram (draw.io / Mermaid)
 Setup instructions (reproducibility)
 Sample outputs (screenshots dashboardu)
 LinkedIn post draft (portfolio showcase)

Code Quality

 .gitignore (credentials, .dlt state)
 requirements.txt (pinned versions)
 Code comments (key logic explanation)
 Folder structure cleanup

GitHub Profile Optimization

 Repository description + topics (data-engineering, dbt, etc)
 README badges (tech stack, build status)
 Project screenshot/GIF v README
 LinkedIn + GitHub cross-link


🚀 Phase 6: Advanced Extensions
LangChain Integration (News & Sentiment)

 Research: LangChain framework basics
 dlt resource: Ticker news ingestion (last 14 days)

API: NewsAPI, Alpha Vantage, or Finnhub
Incremental loading: new articles only


 dbt model: stg_ticker_news with sentiment analysis
 Enhancement: Add news summary to each pipeline run
 Visualization: Sentiment trends alongside price movements

Oceňovací Model (Valuation Framework)

 dbt model: Parametric valuation (DCF, P/E multiples)
 GUI automation: Streamlit app for parameter input

User inputs: growth rate, discount rate, terminal value
Trigger dbt run with custom variables


 Output: Intrinsic value estimates per ticker
 Advanced: Scenario analysis (bull/base/bear cases)

Writeback & User Annotations

 Research: Writeback patterns (BigQuery → user input → BigQuery)
 Implementation: Notes table for manual ticker annotations
 Use case: Investment thesis tracking, watchlist management
 Integration: Link notes to dashboard filters

Data Enrichment

 Complete industry data: yfinance full metadata extraction

Employees, revenue, earnings, forward P/E


 Macro indicators: Add interest rates, VIX (volatility index)
 Alternative data: Reddit sentiment (r/wallstreetbets), Twitter mentions

Sémantický Model (dbt Semantic Layer)

 Setup: dbt semantic layer configuration
 Metrics: Define business metrics (YTD return, Sharpe ratio, drawdown)
 Use case: Consistent metric definitions across BI tools
 Integration: Connect Looker Studio to semantic layer

dbt MCP Server

 Research: MCP (Model Context Protocol) for dbt
 Implementation: Expose dbt metadata via API
 Use case: AI-powered query generation, model discovery
 Integration: Claude/ChatGPT as natural language interface to dbt

Data Quality & Testing

 dbt data quality tests (schema, freshness, anomaly detection)
 Great Expectations integration (pro dlt pipeline)
 Custom macros pro business rules testing
 Data quality dashboard (test failure tracking)

Performance Optimization

 BigQuery partitioning (by date)
 Clustering keys (symbol, sector)
 Incremental materialization tuning (dbt)
 Query optimization (cost reduction)

Scaling & Features

 Expand to full S&P 500 (500 symbols)
 Add crypto data (BTC, ETH via yfinance)
 Real-time streaming (pub/sub alternative)
 PySpark integration (pro large-scale transformations)
 ML models (price prediction, anomaly detection)

CI/CD Pipeline

 GitHub Actions: dbt tests on PR
 Automated deployment (prod/dev environments)
 Pre-commit hooks (SQL linting)
 Semantic versioning (releases)

Cost Optimization Deep Dive

 BigQuery slot reservations analysis
 Data retention policies (archive old data)
 Query result caching strategy
 Free tier monitoring dashboard


📈 Success Metrics

 Pipeline runs without failures (7-day streak)
 Dashboard loads < 3 seconds
 dbt tests 100% passing
 Total monthly cost: $0 (free tier only)
 GitHub stars/engagement tracking
 LinkedIn post: 1000+ views


🔗 Resources & References
Documentation Links

dlt docs: https://dlthub.com/docs
dbt docs: https://docs.getdbt.com
dbt-codegen: https://github.com/dbt-labs/dbt-codegen
dbt-utils: https://github.com/dbt-labs/dbt-utils
yfinance: https://pypi.org/project/yfinance/
BigQuery: https://cloud.google.com/bigquery/docs
LangChain: https://python.langchain.com/docs
Astronomer Cosmos: https://astronomer.github.io/astronomer-cosmos/

Technical Setup

GCP Project ID: dwhhbbi
BigQuery Location: US
Service Account: dwhhbbi-21142b907feb.json
Test Symbols: AAPL, MSFT, GOOGL, AMZN, NVDA
Data Range: 2 roky historie (730 dni)
dbt Project: transformation/stock/
dbt Profile: stock (dev/prod targets)

Tools & Workflow

IDE: VS Code with dbt Fusion extension
Code Review: Claude Code extension (iterative refactoring, debugging)
Version Control: Git (credentials excluded via .gitignore)
Documentation: dbt Core CLI for lineage (dbt docs generate)
Development: dbt Fusion (native VS Code integration)
Testing: dbt test + custom generic tests

Learning Path

 dlt incremental loading patterns
 dlt source, resource, write dispositions
 dbt-bigquery setup and authentication
 dbt-codegen for source automation
 dbt Fusion vs dbt Core feature comparison
 dbt jinja macros deep dive
 dbt window functions best practices
 dbt_utils package patterns
 BigQuery cost optimization course
 Data quality best practices
 LangChain + dlt integration patterns


📝 Session Notes
2025-12-22 (Session 1) - Initial Planning & Setup
Duration: ~1 hour
Focus: Project architecture & dataset selection

Created project roadmap structure
Selected yfinance dataset (stock market data)
Decided on BigQuery-first approach (skip DuckDB initially)
Tech stack finalized: yfinance → dlt → BigQuery → dbt Fusion → Looker Studio
Created project structure (ingestion/, transformation/, orchestration/, logs/)
GCP service account configured

Learnings:

dlt concepts: source, resource, incremental loading, write dispositions
BigQuery authentication (service account JSON)

Next Actions:

dlt init stocks_pipeline bigquery
Create stocks_pipeline.py


2025-12-22 (Session 2) - Pipeline Implementation
Duration: ~2 hours
Focus: First working pipeline
Completed:

✅ dlt init stocks_pipeline bigquery
✅ Created stocks_pipeline.py with 3 resources:

daily_prices (OHLCV data, merge mode)
company_metadata (sector/industry, replace mode)
pipeline_runs (metadata tracking, append mode)


✅ Incremental loading with dlt.sources.incremental()
✅ Error handling per symbol
✅ Logging framework (lokalni soubory + console output)
✅ CLI arguments (--full-refresh)
✅ First successful load: 5 symbols, 2495 rows

Technical Challenges Resolved:

secrets.toml Configuration

Issue: Path backslashes caused TOML parsing errors
Solution: Use forward slashes or double backslashes


yfinance MultiIndex Columns

Issue: df.columns returns tuples, .lower() failed
Solution: Flatten MultiIndex before operations



python   if isinstance(df.columns, pd.MultiIndex):
       df.columns = df.columns.get_level_values(0)

Incremental Cursor Data Type Mismatch

Issue: initial_value string vs date column datetime.date
Solution: Use .date() method consistently



python   initial_value=(datetime.now() - timedelta(days=730)).date()

Pipeline State Management

Issue: State persists in BigQuery + lokalne
Solution: pipeline.drop() clears local state
Full refresh strategy: Drop dataset in BigQuery + pipeline.drop()


Encoding Issues

Issue: Windows console (cp1250) can't render emojis
Solution: Remove emojis from log messages, use UTF-8 for file logging



Code Snippets:
python# Incremental loading
@dlt.resource(
    write_disposition="merge",
    primary_key=["symbol", "date"],
    name="daily_prices"
)
def fetch_daily_prices(
    symbols: list,
    last_date=dlt.sources.incremental(
        "date", 
        initial_value=(datetime.now() - timedelta(days=730)).date()
    )
):
    start_from = last_date.last_value
    # ... fetch logic
python# CLI full refresh
if args.full_refresh:
    pipeline.drop()  # Clear local state
    pipeline = dlt.pipeline(...)  # Re-init
BigQuery Tables Created:

stocks_raw.daily_prices (2495 rows)
stocks_raw.company_metadata (5 rows)
stocks_raw.pipeline_runs (5 rows)
stocks_raw._dlt_pipeline_state (dlt metadata)

Next Actions:

Test incremental load (run zitra, verify only new data)
Expand to S&P 50 symbols
Begin Phase 2: dbt Fusion transformation

Key Takeaways:

dlt.sources.incremental() je powerful, ale data types musi matchovat
Pipeline state management je critical pro full refresh strategie
yfinance vrati MultiIndex columns (potrebuje flatten)
BigQuery + dlt spolupracuji dobre (auto schema creation)


2025-01-25 (Session 3) - dbt Fusion Setup & Staging Layer
Duration: ~2 hours
Focus: dbt-BigQuery connection + Staging models
Completed:

✅ dbt-bigquery package installation (pip install dbt-bigquery)
✅ dbt project initialization (transformation/stock/)
✅ profiles.yml configuration (service account auth)
✅ BigQuery Storage API enabled in GCP Console
✅ Service account permissions fix (BigQuery Read Session User role)
✅ dbt-codegen package installation for source automation
✅ Auto-generated source definitions via generate_source macro
✅ 3 staging models created:

stg_daily_prices.sql
stg_company_metadata.sql
stg_pipeline_runs.sql


✅ dbt tests configured on staging layer
✅ dbt debug validation passed

Technical Challenges Resolved:

Keyfile Path Issues (Windows)

Issue: Unix-style path /Signiture_project/... failed on Windows
Solution: Use absolute path with forward slashes



yaml   keyfile: C:/Users/Username/Signiture_project/ingestion/credentials/dwhhbbi-21142b907feb.json
```

2. **BigQuery Storage API Access Denied**
   - Issue: Service account lacked Storage API permissions
   - Solution 1: Enabled BigQuery Storage API in GCP Console
   - Solution 2: Added `BigQuery Read Session User` role to service account
   - Alternative: Disable Storage API in profiles.yml (not recommended)

3. **dbt-codegen Source Generation**
   - Command: `dbt run-operation generate_source --args '{"schema_name": "stocks_raw", "generate_columns": true, "include_data_types": false}'`
   - Output: Clean source definitions with all columns auto-detected
   - Cleanup: Removed dlt system tables (_dlt_loads, _dlt_pipeline_state, _dlt_version)

**dbt Project Structure:**
```
transformation/stock/
├── dbt_project.yml
├── models/
│   └── staging/
│       ├── schema.yml (source definitions)
│       ├── stg_daily_prices.sql
│       ├── stg_company_metadata.sql
│       └── stg_pipeline_runs.sql
└── macros/
BigQuery Datasets:

stocks_raw (dlt input, read-only for dbt)
stocks_dev (dbt development models)
stocks_marts (dbt production outputs - future)

Next Actions:

Implement intermediate layer (price calculations, moving averages)
Build marts layer (facts, dimensions, aggregations)
Add dbt documentation and lineage visualization
Test incremental materialization strategies

Key Takeaways:

dbt-codegen eliminates manual source definition tedium
BigQuery Storage API significantly speeds up large queries
Windows path handling requires extra attention (forward slashes)
Service account roles matter: Data Editor + Job User + Read Session User
Staging layer should be lightweight (views, minimal transformations)


2025-02-05 (Session 4) - Intermediate Layer Architecture & dbt Fusion Evaluation
Duration: ~1 hour
Focus: int_price_calculations.sql design + Tooling evaluation
Completed:

✅ Intermediate layer architecture designed (3 models planned)
✅ Surrogate key strategy decided (marts layer only, via dbt_utils)
✅ Custom macro concept: calculate_return.sql (reusable safe division)
✅ int_price_calculations.sql structure defined:

Daily returns (LAG window function)
Intraday change (close vs open)
Price range % (volatility proxy)
Typical price ((H+L+C)/3)


✅ dbt Fusion limitations discovered:

No dbt docs generate/serve support
No built-in lineage visualization in VS Code
Workaround: Use dbt Core CLI when docs needed


✅ Claude Code extension workflow established (code review, refactoring)

Technical Decisions:

Surrogate Keys Placement

Staging: Business keys only (symbol, date)
Intermediate: Business logic, no technical PKs
Marts: Surrogate keys via dbt_utils.generate_surrogate_key()


Intermediate Models Design

int_price_calculations.sql - Core metrics (returns, ranges)
int_moving_averages.sql - MA 20/50/200 + crossover signals
int_volatility_metrics.sql - Rolling std dev, annualized vol
int_company_dimension_prep.sql - Pre-dimension for marts (SCD Type 1)
int_sector_dimension_prep.sql - Sector grouping prep


Macro Strategy

calculate_return.sql - Safe division with ROUND (reusable)
Future: calculate_moving_average.sql - Window function wrapper



dbt Fusion vs Core Findings:
Featuredbt Fusiondbt CoreLineage visualization❌ Not available✅ dbt docs serveDocumentation generation❌ Not supported✅ Full supportMacros/tests/packages✅ Full parity✅ Full parityVS Code integration✅ Native⚠️ Requires extensionsIteration speed✅ Faster (inline)⚠️ Terminal-basedProduction readiness✅ Same as Core✅ Industry standard
Recommendation:

Development: dbt Fusion (faster workflow, Claude Code integration)
Documentation: dbt Core (generate lineage when needed)
Production: dbt Core (no Fusion dependency)

Next Actions:

Create macros/calculate_return.sql
Implement int_price_calculations.sql
Create intermediate.yml documentation
Test model: dbt run --select int_price_calculations
Continue to int_moving_averages.sql

Portfolio Talking Points:

Hands-on evaluation of dbt Fusion (cutting-edge tool)
Documented real-world limitations vs marketing claims
Demonstrates tool adaptability (Fusion dev → Core docs/prod)
Claude Code extension for quality assurance

Key Takeaways:

dbt Fusion is production-ready but lacks documentation tooling
VS Code integration trades CLI power for iteration speed
Best practice: Intermediate layer = business logic only (no surrogate keys)
Custom macros essential for DRY principles in dbt
Window functions (LAG, PARTITION BY) core to time-series analysis


2026-02-05 (Session 5) - Intermediate Layer Completion
Duration: ~1 hour
Focus: Complete intermediate layer with all 3 models
Completed:

✅ int_moving_averages.sql - Created and tested

MA 20/50/200 day calculations via AVG() window functions
Golden Cross & Death Cross detection (LAG for previous MAs)
Trend signal classification (5 levels from strong_downtrend to strong_uptrend)
Documentation in intermediate.yml


✅ int_volatility_metrics.sql - Created and tested

20-day and 50-day rolling standard deviation of returns
Annualized volatility calculation (std * sqrt(252))
Volatility regime classification (low/normal/elevated/high)
Trading days count for data quality validation
Documentation in intermediate.yml


✅ CLAUDE.md created - Repository documentation for Claude Code CLI
✅ All intermediate models materialized successfully in BigQuery (view)
✅ project-roadmap.md updated with Phase 2 Intermediate Layer completion

Technical Implementation:

int_moving_averages.sql Structure

CTE 1: staging_prices - Pull close_price from stg_daily_prices
CTE 2: calculate_moving_averages - AVG() OVER with ROWS BETWEEN N PRECEDING
CTE 3: add_previous_mas - LAG() for crossover detection
CTE 4: detect_crossovers - Boolean flags + trend signal CASE statement


int_volatility_metrics.sql Structure

CTE 1: price_calculations - Pull from int_price_calculations (daily_return_pct)
CTE 2: calculate_rolling_volatility - STDDEV() OVER with 20/50 day windows
CTE 3: annualize_volatility - Multiply by SQRT(252), classify volatility regime



Key SQL Patterns Used:

AVG()/STDDEV() OVER (PARTITION BY symbol ORDER BY date ROWS BETWEEN N PRECEDING AND CURRENT ROW)
LAG() for detecting crossovers (comparing current vs previous values)
CASE WHEN for multi-level classification (trend signals, volatility regimes)
COUNT() for data quality checks (trading days in window)

Next Actions:

Begin Marts Layer: dim_companies.sql (SCD Type 1)
Create dim_sectors.sql
Build fct_daily_stock_performance.sql (join all intermediate models)
Implement dbt_utils.generate_surrogate_key() for dimensions

Portfolio Value:

Complete intermediate layer demonstrates:

Financial domain knowledge (moving averages, volatility, crossover signals)
Advanced SQL window functions (AVG, STDDEV, LAG with partitioning)
dbt modular design (3 reusable intermediate models)
Business logic separation (no surrogate keys in intermediate layer)
Documentation best practices (CLAUDE.md for AI-assisted development)


Key Takeaways:

Window functions with ROWS BETWEEN are powerful for time-series calculations
STDDEV() with annualization (sqrt(252)) is industry standard for volatility
Crossover detection requires LAG() to compare current vs previous period
Data quality checks (trading days count) essential for rolling calculations
dbt ref() creates clean dependencies between intermediate models


2026-02-06 (Session 6) - Marts Layer Implementation & Completion
Duration: ~1 hour
Focus: Building dimensional model with fact and dimension tables
Completed:

✅ dim_companies.sql - Created and tested
  - SCD Type 1 dimension with surrogate key from company_symbol
  - Grain: One row per company
  - All tests passed (unique, not_null)

✅ dim_sectors.sql - Created and tested
  - Sector dimension with industry count aggregation
  - Initial implementation error: Used window function causing duplicates
  - Fix: Changed to GROUP BY aggregation for proper grain
  - All tests passed after fix

✅ fct_daily_stock_performance.sql - Created and tested
  - Comprehensive fact table joining all intermediate models
  - FK relationships: company_key → dim_companies, sector_key → dim_sectors
  - Grain: One row per stock_symbol + price_date
  - Initial errors encountered and resolved

✅ marts.yml - Complete documentation for all marts models
  - Column-level descriptions
  - Generic tests (unique, not_null, relationships)
  - Fixed deprecated test syntax for relationships tests

Technical Challenges Resolved:

dim_sectors Duplicate Keys
  - Issue: Window function COUNT() OVER (PARTITION BY sector) created multiple rows per sector
  - Root cause: DISTINCT on (sector, industry) before aggregation created one row per industry
  - Solution: Changed to GROUP BY sector with COUNT(DISTINCT industry)
  - Result: Unique sector_key achieved

fct_daily_stock_performance Errors
  - Issue 1: unique_fct_daily_stock_performance_performance_key failed
  - Issue 2: not_null_fct_daily_stock_performance_company_key failed
  - Root cause: LEFT JOIN allowing NULL values, potential cartesian products
  - Solution: Changed to INNER JOIN on dim_companies, proper FK relationships with dim_sectors
  - Result: All tests passed

Deprecated Test Syntax
  - Issue: relationships tests using old format (to/field at top level)
  - Solution: Migrated to new format with arguments: block
  - Example: relationships: { arguments: { to: ref('dim_companies'), field: company_key }}

Key SQL Patterns Used:

GROUP BY for dimension aggregation (dim_sectors)
INNER JOIN for mandatory FK relationships (dim_companies)
LEFT JOIN for optional dimensions (dim_sectors when sector can be NULL)
dbt_utils.generate_surrogate_key() for all dimension and fact surrogate keys
Proper FK testing with relationships tests

Analytics Engineering Lessons:

Always preview data with dbt show before writing transformations
GROUP BY > window functions for dimension tables (ensures grain)
INNER JOIN when FK must be NOT NULL, LEFT JOIN when optional
Test-driven development: Run dbt test after each model creation
Fix errors iteratively: one model at a time, validate after each fix
Follow dimensional modeling best practices: proper grain, surrogate keys, FK relationships

dbt Testing Results:

Total tests: 16
Passed: 16
Failed: 0 (after fixes)
Coverage: Unique constraints, not null, FK relationships

Next Actions:

✅ Phase 2 Complete - All transformation layers built
➡️ Phase 3: Orchestration - Select scheduler (GitHub Actions, Dagster, Airflow, Cloud Scheduler)
➡️ Phase 4: Visualization - Build Looker Studio dashboards
Future enhancements: agg_portfolio_summary.sql, agg_sector_performance.sql

Portfolio Value:

Complete dimensional model demonstrates:
- Star schema design (fact + dimensions)
- Proper surrogate key generation with dbt_utils
- FK relationships with referential integrity testing
- Analytics engineering best practices (grain, testing, documentation)
- Iterative debugging and problem-solving skills
- Understanding of dbt testing framework
- Data modeling fundamentals (SCD Type 1, fact tables, dimensions)


Last Updated: 2026-02-06 17:00 CET
Next Milestone: Phase 3 - Orchestration (Scheduler Selection & Implementation)