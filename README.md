# Stock Market Data Pipeline

Fully automated end-to-end data pipeline for stock market analysis using modern data engineering stack.

## 📊 Project Overview

Automated ETL pipeline that ingests daily stock market data, transforms it into analytics-ready models, and runs on a scheduled basis using GitHub Actions.

**Tech Stack:**
- **Ingestion**: dlt (data load tool) + yfinance API
- **Storage**: Google BigQuery
- **Transformation**: dbt (data build tool)
- **Data Quality**: Elementary Data (observability & monitoring)
- **Orchestration**: GitHub Actions
- **Visualization**: Looker Studio (planned)

## 🏗️ Architecture

```
GitHub Actions (Daily 8:00 UTC)
         ↓
┌─────────────────────┐
│  yfinance API       │
│  (13 stock symbols) │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  dlt Pipeline       │
│  Incremental Load   │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  BigQuery           │
│  stocks_raw dataset │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│  dbt Transformation │
│  3-layer medallion  │
│  ├─ Staging         │
│  ├─ Intermediate    │
│  └─ Marts           │
└──────────┬──────────┘
           ↓           ↓
┌─────────────────────┐  ┌──────────────────┐
│  Analytics Models   │  │  Elementary      │
│  ├─ dim_companies   │  │  Data Quality    │
│  ├─ dim_sectors     │  │  Monitoring      │
│  └─ fct_daily_...   │  └──────────────────┘
└─────────────────────┘
```

## ✨ Features

- ✅ **Fully Automated**: GitHub Actions runs pipeline daily without manual intervention
- ✅ **Incremental Loading**: Only fetches new data since last run (efficient)
- ✅ **Data Quality**: Comprehensive dbt tests + Elementary observability platform
- ✅ **Data Observability**: Automated test tracking, anomaly detection, schema change monitoring
- ✅ **Auto-published Documentation**: dbt docs + Elementary reports published to GitHub Pages
- ✅ **Modular Design**: Clean separation between staging, intermediate, and marts layers
- ✅ **Well Documented**: Extensive inline comments and documentation
- ✅ **Educational**: Built as a portfolio/learning project with detailed explanations

## 📚 Live Documentation

**Auto-published on GitHub Pages** (updated daily):
- 🔗 **[dbt Docs](https://briza5.github.io/Signiture_project/)** - Interactive data model documentation, DAG lineage
- 🔗 **[Elementary Report](https://briza5.github.io/Signiture_project/elementary.html)** - Data quality monitoring & test results

## 📁 Project Structure

```
Signiture_project/
├── ingestion/                  # dlt pipeline for data ingestion
│   ├── stock_pipeline.py      # Main pipeline (yfinance → BigQuery)
│   ├── .dlt/                  # dlt configuration (not in git)
│   └── credentials/           # BigQuery credentials (not in git)
│
├── transformation/             # dbt project for data transformation
│   ├── models/
│   │   ├── staging/           # 3 models: stg_daily_prices, stg_company_metadata, stg_pipeline_runs
│   │   ├── intermediate/      # 3 models: price calculations, moving averages, volatility
│   │   └── marts/             # 3 models: dim_companies, dim_sectors, fct_daily_stock_performance
│   ├── macros/
│   │   ├── calculate_return.sql          # Custom return calculation macro
│   │   ├── cents_to_dollars.sql          # Currency conversion macro
│   │   └── bigquery_timestamp_fix.sql    # Elementary BigQuery compatibility fix
│   ├── dbt_packages/          # Installed packages: dbt_utils, codegen, elementary
│   ├── profiles.yml           # dbt connection configuration
│   └── dbt_project.yml        # dbt project settings
│
├── orchestration/              # Pipeline orchestration
│   ├── README.md              # Orchestration overview
│   └── github-actions/
│       ├── setup.md           # Step-by-step GitHub Actions setup
│       ├── github-pages.md    # GitHub Pages documentation deployment guide
│       └── secrets.env.example # GitHub Secrets template
│
├── .github/workflows/          # GitHub Actions workflows
│   └── stocks-pipeline.yml    # Main pipeline workflow (350+ lines, fully commented)
│
├── docs/                       # Project documentation
│   └── project-roadmap.md     # Detailed project roadmap and session notes
│
├── logs/                       # Pipeline execution logs (not in git)
├── CLAUDE.md                   # Instructions for Claude Code CLI
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Google Cloud Platform account with BigQuery enabled
- Service account with BigQuery permissions
- GitHub account (for orchestration)

### Local Development Setup

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd Signiture_project
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure credentials**
   ```bash
   # Place service account JSON in ingestion/credentials/
   cp your-service-account.json ingestion/credentials/dwhhbbi-credentials.json

   # Configure dlt secrets
   cp ingestion/.dlt/secrets.toml.example ingestion/.dlt/secrets.toml
   # Edit secrets.toml with your credentials
   ```

4. **Run ingestion pipeline**
   ```bash
   cd ingestion
   python stock_pipeline.py
   ```

5. **Run dbt transformation**
   ```bash
   cd transformation
   dbt deps  # Install dbt packages (dbt_utils, codegen, elementary)
   dbt build # Build all models and run tests
   ```

6. **Generate Elementary data quality report**
   ```bash
   cd transformation
   edr report --profiles-dir .  # Generates HTML report
   ```

### GitHub Actions Setup

See [`orchestration/github-actions/setup.md`](orchestration/github-actions/setup.md) for detailed instructions.

**Summary:**
1. Push repository to GitHub
2. Configure GitHub Secret: `BIGQUERY_CREDENTIALS` (service account JSON)
3. Enable GitHub Actions
4. Workflow runs automatically every weekday at 8:00 UTC

**Note:** Only 1 secret required! Workflow uses `GOOGLE_APPLICATION_CREDENTIALS` standard.

## 📊 Data Models

### Staging Layer (Views)
- `stg_daily_prices`: Cleaned OHLCV data
- `stg_company_metadata`: Company information
- `stg_pipeline_runs`: Pipeline execution logs

### Intermediate Layer (Views)
- `int_price_calculations`: Daily returns, intraday changes, price ranges
- `int_moving_averages`: 20/50/200-day MAs, golden/death crosses, trend signals
- `int_volatility_metrics`: Rolling volatility, annualized volatility, regime classification

### Marts Layer (Tables)
- `dim_companies`: Company dimension (SCD Type 1)
- `dim_sectors`: Sector dimension with aggregations
- `fct_daily_stock_performance`: Comprehensive fact table (OHLCV + all metrics)

## 🔧 Configuration

### Stock Symbols
Currently tracking 13 symbols (defined in `ingestion/stock_pipeline.py`):
- **Tech**: AAPL, MSFT, GOOGL, AMZN, AMD, NFLX, INTC, PLTR, SNOW
- **Media**: DIS
- **Pharma**: BMY
- **SaaS**: CRM
- **REIT**: O

### BigQuery Datasets
- `stocks_raw`: Raw data from dlt pipeline
- `stocks_dev_staging`: Staging layer views
- `stocks_dev_intermediate`: Intermediate layer views
- `stocks_dev_marts`: Marts layer tables (production-ready)
- `stocks_dev_elementary`: Elementary data quality monitoring tables

## 📈 Project Status

- ✅ **Phase 1**: Data Ingestion (dlt → BigQuery) - COMPLETE
- ✅ **Phase 2**: Transformation (dbt staging/intermediate/marts) - COMPLETE
- ✅ **Phase 3**: Orchestration (GitHub Actions) - COMPLETE
- ✅ **Phase 3.5**: Data Observability (Elementary) - COMPLETE
- ✅ **Phase 3.6**: GitHub Pages Documentation - COMPLETE
- 🔄 **Phase 4**: Visualization (Looker Studio) - IN PROGRESS
- 🔄 **Phase 5**: Enhancements (alerts, data expansion, ML) - PLANNED

See [`docs/project-roadmap.md`](docs/project-roadmap.md) for detailed progress tracking.

## 🎓 Learning Highlights

This project demonstrates:
- **Modern Data Stack**: dlt + dbt + BigQuery + Elementary + GitHub Actions
- **DataOps**: CI/CD for data pipelines, automated testing, artifact management
- **Data Observability**: Elementary for test tracking, anomaly detection, schema monitoring
- **Analytics Engineering**: Dimensional modeling, surrogate keys, FK relationships
- **Advanced dbt**: Custom macros, adapter dispatch overrides, package namespace configuration
- **Best Practices**: DRY principles, modular design, comprehensive documentation
- **Problem Solving**: BigQuery timestamp precision, dbt macro overrides, schema naming patterns

## 📝 Documentation

**Live Documentation (GitHub Pages):**
- 🔗 **[dbt Docs](https://briza5.github.io/Signiture_project/)**: Interactive model documentation
- 🔗 **[Elementary Report](https://briza5.github.io/Signiture_project/elementary.html)**: Data quality monitoring

**Project Documentation:**
- **[CLAUDE.md](CLAUDE.md)**: Instructions for Claude Code CLI
- **[project-roadmap.md](docs/project-roadmap.md)**: Detailed roadmap with session notes
- **[GitHub Actions Setup](orchestration/github-actions/setup.md)**: Complete setup guide
- **[GitHub Pages Setup](orchestration/github-actions/github-pages.md)**: Documentation deployment guide
- **[Orchestration Overview](orchestration/README.md)**: Scheduler comparison

## 🤝 Contributing

This is a personal portfolio/learning project. Feedback and suggestions are welcome!

## 📄 License

This project is for educational and portfolio purposes.

## 🔗 Resources

- [dlt Documentation](https://dlthub.com/docs)
- [dbt Documentation](https://docs.getdbt.com)
- [Elementary Documentation](https://docs.elementary-data.com)
- [yfinance Documentation](https://pypi.org/project/yfinance/)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Last Updated**: 2026-02-15
**Status**: Phase 3.6 Complete - Auto-published documentation on GitHub Pages ✅
