# GitHub Actions Setup Guide

Kompletní návod pro nastavení automatizované orchestrace pomocí GitHub Actions.

## Prerekvizity

- ✅ GitHub account
- ✅ Git repository inicializovaný v projektu
- ✅ BigQuery service account s credentials JSON
- ✅ Funkční lokální pipeline (dlt + dbt)

## Krok 1: Připravit Projekt pro GitHub

### 1.1 Ověřit .gitignore

Ujistěte se, že citlivé soubory NEJSOU v gitu:

```bash
# Check že tyto soubory nejsou tracked
git status

# Měly by být ignored:
ingestion/.dlt/secrets.toml
ingestion/credentials/*.json
transformation/credentials/*.json
.venv/
```

### 1.2 Vytvořit GitHub Repository

**Varianta A: Nové repo**
```bash
# Na GitHubu: Create new repository (bez README, .gitignore)
# Lokálně:
git remote add origin https://github.com/your-username/stock-portfolio-pipeline.git
git branch -M master
git push -u origin master
```

**Varianta B: Existující repo**
```bash
# Pokud už máte remote:
git push origin master
```

---

## Krok 2: Nastavit GitHub Secrets

GitHub Secrets = šifrované environment variables pro CI/CD

### 2.1 Navigace v GitHub UI

```
Your Repository → Settings → Secrets and variables → Actions → New repository secret
```

### 2.2 Vytvořit Secrets

#### Secret 1: `BIGQUERY_CREDENTIALS`
```
Name: BIGQUERY_CREDENTIALS
Value: <celý obsah service account JSON souboru>
```

**Jak získat:**
```bash
# Windows PowerShell
Get-Content "D:\OneDrive\Data engineer\Projekty\Signiture_project\ingestion\credentials\dwhhbbi-21142b907feb.json" | Set-Clipboard

# Pak Ctrl+V do GitHub Secret value field
```

**Formát (pro referenci):**
```json
{
  "type": "service_account",
  "project_id": "dwhhbbi",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "...",
  "client_id": "...",
  ...
}
```

#### Secret 2: `GCP_PROJECT_ID`
```
Name: GCP_PROJECT_ID
Value: dwhhbbi
```

#### Secret 3: `BIGQUERY_PRIVATE_KEY`
```
Name: BIGQUERY_PRIVATE_KEY
Value: <private_key z JSON credentials>
```

**Jak extrahovat:**
```python
# Python one-liner
import json
with open('ingestion/credentials/dwhhbbi-21142b907feb.json') as f:
    data = json.load(f)
    print(data['private_key'])

# Zkopíruj output včetně -----BEGIN PRIVATE KEY----- a -----END PRIVATE KEY-----
```

#### Secret 4: `BIGQUERY_CLIENT_EMAIL`
```
Name: BIGQUERY_CLIENT_EMAIL
Value: <client_email z JSON credentials>
```

**Jak extrahovat:**
```python
# Python
import json
with open('ingestion/credentials/dwhhbbi-21142b907feb.json') as f:
    data = json.load(f)
    print(data['client_email'])

# Output: something@dwhhbbi.iam.gserviceaccount.com
```

### 2.3 Verify Secrets

Po přidání všech secrets:
```
Settings → Secrets and variables → Actions
```

Měli byste vidět:
- `BIGQUERY_CREDENTIALS`
- `GCP_PROJECT_ID`
- `BIGQUERY_PRIVATE_KEY`
- `BIGQUERY_CLIENT_EMAIL`

⚠️ **Pozor**: Nemůžete zobrazit hodnotu secrets po uložení (jen název)

---

## Krok 3: Enable GitHub Actions

### 3.1 Repository Settings

```
Settings → Actions → General
```

### 3.2 Permissions

**Workflow permissions:**
- ☑️ Read and write permissions (pro uploading artifacts)

**Actions permissions:**
- ☑️ Allow all actions and reusable workflows

### 3.3 Verify Workflow File

Zkontrolujte že `.github/workflows/stocks-pipeline.yml` existuje:

```bash
ls .github/workflows/
# Output: stocks-pipeline.yml
```

---

## Krok 4: První Test Run

### 4.1 Manual Trigger (Doporučeno pro první run)

```
GitHub → Actions tab → "Stock Market Data Pipeline" → Run workflow
```

**Options:**
- Branch: `master`
- Full refresh: `☐` (unchecked pro incremental)

Click **"Run workflow"** 🚀

### 4.2 Sledovat Progress

```
Actions → workflow run (čerstvý běh)
```

**Live view:**
- ✅ Green = success
- ❌ Red = failure
- 🟡 Yellow = running

**Expand jobs** pro details:
1. Ingest Stock Data (dlt)
2. Transform Data (dbt)
3. Send Notifications

### 4.3 Check Artifacts

Po dokončení:
```
Workflow run → Artifacts (scroll down)
```

Download:
- `pipeline-logs` - dlt execution logs
- `dbt-artifacts` - dbt manifest & results

---

## Krok 5: Verify v BigQuery

### 5.1 Check Data Freshness

```sql
-- Ověř že data byla načtena
SELECT
    MAX(date) as latest_date,
    COUNT(*) as row_count
FROM `dwhhbbi.stocks_raw.daily_prices`;
```

Expected:
- `latest_date` = dnes nebo včera (záleží na market open)
- `row_count` > 0

### 5.2 Check dbt Models

```sql
-- Verify marts layer
SELECT COUNT(*)
FROM `dwhhbbi.stocks_dev_marts.fct_daily_stock_performance`;
```

---

## Krok 6: Scheduled Runs (Automatizace)

### 6.1 Cron Schedule

Workflow se automaticky spustí:
- **Kdy**: Každý všední den v 8:00 AM UTC
- **Timezone**: UTC (= 9:00 CET v zimě, 10:00 CEST v létě)
- **Cron**: `0 8 * * 1-5`

### 6.2 Adjust Schedule (Optional)

Editovat `.github/workflows/stocks-pipeline.yml`:

```yaml
schedule:
  # Příklad: Změna na 6:00 AM UTC
  - cron: '0 6 * * 1-5'
```

**Cron syntax reference:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
* * * * *
```

---

## Troubleshooting

### Problem: "Secrets not found"

**Symptom**: Workflow failuje s "Required secrets not set"

**Fix:**
1. Verify secrets existence: Settings → Secrets
2. Check jména secrets (case-sensitive)
3. Re-create secret pokud má typo

### Problem: BigQuery authentication failed

**Symptom**: "Could not authenticate to BigQuery"

**Fix:**
1. Verify `BIGQUERY_CREDENTIALS` obsahuje platný JSON
2. Check service account má permissions:
   - BigQuery Data Editor
   - BigQuery Job User
   - BigQuery Read Session User

### Problem: dbt build fails

**Symptom**: `dbt build` krok failuje

**Fix:**
1. Check dbt artifacts pro error message
2. Verify `prod` target v `profiles.yml`
3. Test `dbt debug` lokálně
4. Check environment variable `DBT_BIGQUERY_KEYFILE`

### Problem: Workflow není visible

**Symptom**: Nevidím workflow v Actions tab

**Fix:**
1. Verify `.github/workflows/stocks-pipeline.yml` je committed
2. Push na GitHub: `git push origin master`
3. Wait 1-2 minuty pro GitHub indexing
4. Refresh Actions tab

---

## Notifications Setup (Optional)

### Email Notifications

GitHub automaticky pošle email při workflow failure pokud:
1. Settings → Notifications → Actions
2. ☑️ "Send notifications for failed workflows"

### Slack Notifications (Advanced)

Přidat Slack webhook do workflow:

```yaml
# V notify job, přidat step:
- name: Slack Notification
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "❌ Stock Pipeline Failed!",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Pipeline Status:* Failed\n*Run:* ${{ github.run_id }}"
            }
          }
        ]
      }
```

---

## Security Best Practices

✅ **DO:**
- Store všechny credentials v GitHub Secrets
- Use environment variables v code
- Rotate service account keys pravidelně
- Limit service account permissions (principle of least privilege)

❌ **DON'T:**
- Commit credentials do git (ani v .env files)
- Share secrets přes email/Slack
- Use personal accounts místo service accounts
- Hardcode credentials v kódu

---

## Cost Monitoring

### GitHub Actions Free Tier
- **Limit**: 2000 minutes/měsíc
- **Estimated usage**: ~10 min/den = ~220 min/měsíc
- **Overhead**: ✅ Plenty of headroom

### BigQuery Costs
- **Query costs**: ~$0.01/den (small dataset)
- **Storage costs**: ~$0.02/GB/měsíc
- **Total estimated**: < $5/měsíc

**Monitor:**
```
GCP Console → Billing → Reports
Filter: Product = BigQuery
```

---

## Next Steps

Po úspěšném setup:

1. ✅ Verify scheduled runs fungují
2. ✅ Monitor pipeline logs v Actions UI
3. ✅ Check BigQuery data freshness daily
4. 🔄 Consider Slack notifications
5. 🔄 Add data quality tests
6. 🔄 Create production dataset (`stocks_prod`)

---

## Reference

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Cron Syntax](https://crontab.guru/)
- [BigQuery Service Accounts](https://cloud.google.com/bigquery/docs/authentication/service-account-file)
