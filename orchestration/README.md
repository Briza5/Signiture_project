# Orchestration

Tato složka obsahuje konfiguraci a dokumentaci pro automatizaci (orchestraci) Stock Market Data Pipeline.

## Dostupné Schedulery

### 1. GitHub Actions ✅ (Implementováno)
- **Cesta**: `.github/workflows/stocks-pipeline.yml`
- **Dokumentace**: `github-actions/setup.md`
- **Trigger**: Cron (8:00 UTC weekdays) + manuální spuštění
- **Cost**: $0 (Free tier: 2000 min/měsíc)
- **Status**: ✅ Ready to use

### 2. Dagster Cloud (Plánováno)
- **Status**: 🔄 Not implemented yet
- **Cost**: Free tier available
- **Use case**: Advanced orchestration s UI a monitoring

### 3. Apache Airflow (Plánováno)
- **Status**: 🔄 Not implemented yet
- **Cost**: Self-hosted (compute costs)
- **Use case**: Production-grade orchestration

### 4. GCP Cloud Scheduler + Cloud Run (Plánováno)
- **Status**: 🔄 Not implemented yet
- **Cost**: Pay-per-use
- **Use case**: Native GCP integration

## Quick Start (GitHub Actions)

1. **Push projekt na GitHub**
   ```bash
   git remote add origin https://github.com/your-username/your-repo.git
   git push -u origin master
   ```

2. **Nastavit GitHub Secrets**
   - Viz `github-actions/setup.md`

3. **Enable GitHub Actions**
   - GitHub → Settings → Actions → General → Allow all actions

4. **První run**
   - GitHub → Actions → Stock Market Data Pipeline → Run workflow

## Architektura

```
Trigger (Cron/Manual)
    ↓
Job 1: Ingestion (dlt)
    ├─ Setup Python environment
    ├─ Install dependencies
    ├─ Configure credentials
    ├─ Run stock_pipeline.py
    └─ Upload logs
    ↓
Job 2: Transformation (dbt)
    ├─ Setup Python + dbt
    ├─ Configure credentials
    ├─ Run dbt build
    └─ Upload artifacts
    ↓
Job 3: Notification
    ├─ Check status
    └─ Create summary
```

## Monitoring

### GitHub Actions UI
- **Logs**: GitHub → Actions → workflow run → job → step logs
- **Artifacts**: Logs a dbt artifacts ke stažení
- **Notifications**: Email při failure (GitHub nastavení)

### BigQuery Monitoring
- **Pipeline runs**: `stocks_raw.pipeline_runs` table
- **Data freshness**: Query max(date) from daily_prices
- **Costs**: BigQuery → Billing dashboard

## Development vs Production

| Environment | Scheduler | Target | Dataset |
|------------|-----------|--------|---------|
| **Local** | Manual (`python stock_pipeline.py`) | `dev` | `stocks_dev` |
| **CI/CD** | GitHub Actions | `prod` | `stocks_dev` |
| **Future** | Dagster/Airflow | `prod` | `stocks_prod` |

## Troubleshooting

### GitHub Actions Fails
1. Check logs v GitHub Actions UI
2. Verify secrets jsou nastavené
3. Check BigQuery permissions
4. Test pipeline lokálně

### dbt Build Fails
1. Check dbt artifacts (manifest.json, run_results.json)
2. Verify credentials path
3. Run `dbt debug` lokálně
4. Check BigQuery dataset existence

## Next Steps

- [ ] Add Slack/Email notifications
- [ ] Implement Dagster for better UI
- [ ] Add data quality monitoring
- [ ] Create production dataset (`stocks_prod`)
- [ ] Add cost alerts
