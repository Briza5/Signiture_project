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

### 2.2 Vytvořit Secret (pouze 1 potřebný!)

#### `BIGQUERY_CREDENTIALS` (JEDINÝ potřebný secret)
```
Name: BIGQUERY_CREDENTIALS
Value: <celý obsah service account JSON souboru>
```

**Jak získat:**
```bash
# Windows PowerShell
Get-Content "ingestion\credentials\dwhhbbi-credentials.json" | Set-Clipboard

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
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

**Proč pouze 1 secret?**
- Workflow používá `GOOGLE_APPLICATION_CREDENTIALS` environment variable
- Google Cloud automaticky načte celý JSON soubor
- Není potřeba parsovat individual fields (private_key, client_email) do TOML
- Vyhýbáme se problémům s TOML escapováním newlines v private_key

### 2.3 Verify Secret

Po přidání secretu:
```
Settings → Secrets and variables → Actions
```

Měli byste vidět:
- ✅ `BIGQUERY_CREDENTIALS`

⚠️ **Pozor**: Nemůžete zobrazit hodnotu secretu po uložení (jen název)

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
1. Verify secret existence: Settings → Secrets → Actions
2. Check secret name je přesně `BIGQUERY_CREDENTIALS` (case-sensitive)
3. Re-create secret pokud má typo

### Problem: Missing credentials directory

**Symptom**: `No such file or directory: ingestion/credentials/dwhhbbi-credentials.json`

**Fix:** ✅ Již vyřešeno ve workflow
- Workflow nyní obsahuje `mkdir -p ingestion/credentials` před vytvořením JSON file
- Pokud problém přetrvává, verify Step 4 v Job 1 obsahuje mkdir příkaz

### Problem: TOML parse error (DEPRECATED)

**Symptom**: `Control characters (codes less than 0x1f and 0x7f) are not allowed in strings`

**Fix:** ✅ Již vyřešeno pomocí GOOGLE_APPLICATION_CREDENTIALS
- Starý přístup: Parsování individual fields do TOML (nefungovalo kvůli newlines v private_key)
- Nový přístup: Celý JSON jako soubor + GOOGLE_APPLICATION_CREDENTIALS env var
- Workflow již používá správný přístup

### Problem: YAML syntax errors

**Symptom**: `Implicit map keys need to be followed by map values at line X`

**Fix:** ✅ Již vyřešeno ve workflow
- Problém: Heredoc syntax s TOML obsahem zmátl YAML parser
- Řešení: Použití simple echo commands místo heredoc
- Workflow nyní používá: `echo "[destination.bigquery]" > file`

### Problem: Logs artifact warning

**Symptom**: `No files were found with the provided path: logs/pipeline_run_*.log`

**Fix:** ✅ Již vyřešeno ve workflow
- Workflow nyní obsahuje `if-no-files-found: warn` v upload artifact step
- Pouze warning místo error pokud logy neexistují (např. při early failure)

### Problem: BigQuery authentication failed

**Symptom**: "Could not authenticate to BigQuery"

**Fix:**
1. Verify `BIGQUERY_CREDENTIALS` secret obsahuje platný JSON (celý soubor)
2. Check JSON formát je správný (valid JSON syntax)
3. Verify service account má permissions:
   - BigQuery Data Editor
   - BigQuery Job User
   - BigQuery Read Session User
4. Check GOOGLE_APPLICATION_CREDENTIALS env var je nastavena ve workflow

### Problem: dbt build fails

**Symptom**: `dbt build` krok failuje

**Fix:**
1. Check dbt artifacts pro error message (download z workflow artifacts)
2. Verify `prod` target existuje v `transformation/profiles.yml`
3. Verify `DBT_BIGQUERY_KEYFILE` env var je nastavena v Job 2, Step 4
4. Test `dbt debug --target prod` lokálně
5. Check BigQuery dataset `stocks_dev` existuje

### Problem: Workflow není visible

**Symptom**: Nevidím workflow v Actions tab

**Fix:**
1. Verify `.github/workflows/stocks-pipeline.yml` je committed a pushed
2. Check YAML syntax je validní (použij YAML validator)
3. Push na GitHub: `git push origin master`
4. Wait 1-2 minuty pro GitHub indexing
5. Refresh Actions tab
6. Check Settings → Actions → General: "Allow all actions" je enabled

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
