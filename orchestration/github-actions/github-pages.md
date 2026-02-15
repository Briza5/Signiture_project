# GitHub Pages Documentation Setup

Automatická publikace **dbt dokumentace** a **Elementary data quality reportů** na GitHub Pages.

## 📚 Přehled

Pipeline automaticky generuje a publikuje dva typy dokumentace:

1. **dbt Docs** - Interaktivní dokumentace data modelů, DAG lineage, column-level metadata
2. **Elementary Report** - Data quality monitoring, test results, anomaly detection

**Live dokumentace:** https://briza5.github.io/Signiture_project/

---

## Prerekvizity

- ✅ Funkční GitHub Actions workflow (viz [setup.md](setup.md))
- ✅ Repository s enabled GitHub Pages
- ✅ Úspěšný běh `transform-data` jobu (generuje dbt docs + Elementary report)

---

## Krok 1: Enable GitHub Pages

### 1.1 Repository Settings

```
Your Repository → Settings → Pages
```

### 1.2 Configure Source

**Build and deployment:**
- **Source**: ✅ **GitHub Actions** (NE "Deploy from a branch")
- ⚠️ **Důležité**: NEPOUŽÍVAT "Deploy from a branch" - používáme deployment API

**Static site generator:**
- GitHub automaticky detekuje static HTML
- `.nojekyll` soubor vypíná Jekyll processing (workflow ho vytváří automaticky)

### 1.3 Verify Settings

Po uložení byste měli vidět:
```
✅ Your site is ready to be published at https://<username>.github.io/<repo>/
```

Po prvním successful workflow run:
```
✅ Your site is live at https://briza5.github.io/Signiture_project/
```

---

## Krok 2: Workflow Execution

### 2.1 Automated Deployment

Dokumentace se automaticky publikuje při každém successful workflow run:

**Trigger:**
1. Scheduled runs (cron: každý všední den 8:00 UTC)
2. Manual trigger (workflow_dispatch)

**Deployment proces:**
```
transform-data job
  ↓
  └─ dbt docs generate (index.html, manifest.json, catalog.json)
  └─ edr report (elementary_report.html)
  └─ Upload artifacts
       ↓
deploy-docs job
  ↓
  └─ Download artifacts
  └─ Prepare GitHub Pages structure
  └─ Upload Pages artifact
  └─ Deploy to GitHub Pages ✅
```

### 2.2 Manual Trigger (Pro test)

```
GitHub → Actions → "Stock Market Data Pipeline" → Run workflow
```

**Options:**
- Branch: `master`
- Full refresh: `☐` (unchecked)

**Expected time:** ~5-10 minut (závisí na velikosti dat)

---

## Krok 3: Accessing Documentation

### 3.1 Published URLs

**Homepage (dbt Docs):**
- 🔗 https://briza5.github.io/Signiture_project/
- Interaktivní DAG lineage viewer
- Model documentation s SQL + column descriptions
- Test results inline

**Elementary Report:**
- 🔗 https://briza5.github.io/Signiture_project/elementary.html
- Data quality dashboard
- Test run history
- Anomaly detection
- Schema change tracking

### 3.2 Finding URLs in Workflow

Po successful deployment, workflow summary obsahuje odkazy:

```
GitHub → Actions → Workflow run → Summary

📚 Documentation Links
- dbt Docs
- Elementary Report
```

---

## Krok 4: Understanding Documentation Structure

### 4.1 dbt Docs Features

**Hlavní navigace:**
- **Project**: Overview projektu, všechny modely
- **Database**: Browse podle schemas (staging, intermediate, marts)
- **Graph**: DAG visualization (lineage + dependencies)

**Model detail page:**
- SQL source code (compiled + raw)
- Column descriptions + data types
- Tests (generic + singular)
- Dependencies (upstream + downstream)
- Metadata (last modified, materialization)

**Search:**
- Full-text search across models, columns, descriptions
- Keyboard shortcut: `/` (focus search)

### 4.2 Elementary Report Features

**Dashboard sections:**
1. **Test Runs** - Historie všech dbt testů (passed/failed/warned)
2. **Models** - Model health metrics, run times, freshness
3. **Test Results** - Detailed test failures s context
4. **Lineage** - Model dependencies visualization
5. **Schema Changes** - Column additions/deletions/type changes

**Filters:**
- Time range (7 days, 30 days, custom)
- Test status (all, failed, passed)
- Model name search

---

## Workflow Architecture

### Job 3: deploy-docs (GitHub Pages Deployment)

**Permissions:**
```yaml
permissions:
  pages: write      # Nutné pro deployment API
  id-token: write   # Nutné pro OIDC authentication
```

**Environment:**
```yaml
environment:
  name: github-pages
  url: ${{ steps.deployment.outputs.page_url }}
```

**Steps:**

#### STEP 1: Download documentation artifacts
```yaml
- uses: actions/download-artifact@v4
  with:
    name: documentation
    path: ./docs
```

Stahuje artifacts z `transform-data` jobu:
- `target/index.html`, `manifest.json`, `catalog.json`, `graph.gpickle`
- `edr_target/elementary_report.html`

#### STEP 2: Prepare GitHub Pages structure
```bash
mkdir -p gh-pages
touch gh-pages/.nojekyll  # Disable Jekyll processing
cp -r docs/target/* gh-pages/
cp docs/edr_target/elementary_report.html gh-pages/elementary.html
```

**Directory structure:**
```
gh-pages/
├── .nojekyll                 # Vypíná Jekyll
├── index.html                # dbt docs homepage
├── manifest.json             # dbt model metadata
├── catalog.json              # BigQuery column metadata
├── graph.gpickle             # DAG graph data
├── elementary.html           # Elementary report
└── README.md                 # Dokumentace (GitHub view only)
```

#### STEP 3-5: Deploy to GitHub Pages
```yaml
- uses: actions/configure-pages@v5
- uses: actions/upload-pages-artifact@v3
  with:
    path: ./gh-pages
- uses: actions/deploy-pages@v4
```

**Deployment method:**
- ✅ GitHub Pages deployment API (oficiální)
- ❌ NE git push do gh-pages branch (deprecated)
- ✅ Žádné extra permissions potřeba (používá OIDC)

---

## Error Handling & Fallbacks

### Elementary Report Missing

Pokud `edr report` failne, deployment NEPŘERUŠÍ:

**Fallback HTML:**
```html
<html>
<body>
  <h1>Elementary Report Not Available</h1>
  <p>Report generation failed or was skipped.</p>
</body>
</html>
```

**README.md status:**
```markdown
- [Elementary Report](elementary.html) - Data quality monitoring (⚠️ Not Generated)
```

**Check v workflow logs:**
```
=== Downloaded artifact structure ===
target/
  index.html ✅
  manifest.json ✅
  catalog.json ✅
edr_target/
  elementary_report.html ⚠️ (missing - fallback created)
```

---

## Troubleshooting

### Problem: GitHub Pages shows 404

**Symptom:** Návštěva https://briza5.github.io/Signiture_project/ shows 404

**Fix:**
1. Verify Settings → Pages → Source = **"GitHub Actions"**
2. Check deploy-docs job úspěšně proběhl:
   ```
   Actions → Workflow run → deploy-docs ✅
   ```
3. Wait 1-2 minuty po deployment (GitHub Pages propagation)
4. Hard refresh browser: `Ctrl+Shift+R` (Windows) / `Cmd+Shift+R` (Mac)

### Problem: dbt docs nefunguje (blank page)

**Symptom:** index.html se načte, ale je prázdný nebo chybí DAG

**Possible causes:**

**1. Missing manifest.json nebo catalog.json**
```bash
# Check v workflow artifacts:
Actions → Workflow run → Artifacts → documentation → download
```

**Fix:** Verify `dbt docs generate` proběhl úspěšně v transform-data job

**2. Jekyll processing (soubory s _ jsou ignorovány)**
```bash
# Check .nojekyll exists v gh-pages artifact
```

**Fix:** ✅ Workflow automaticky vytváří `.nojekyll` - verify v Prepare GitHub Pages content step

**3. Browser cache**
```bash
# Hard refresh: Ctrl+Shift+R
# Nebo: DevTools → Network → Disable cache
```

### Problem: Elementary report shows "Not Available"

**Symptom:** elementary.html ukazuje fallback HTML

**Diagnosis:**
1. Check transform-data job logs:
   ```
   Actions → Workflow run → transform-data → Generate Elementary report
   ```
2. Look for error messages:
   ```
   ERROR — Could not generate the report - Error: Failed to run dbt command
   ```

**Common causes:**
- Elementary profile credentials chybí nebo jsou špatně (verify `profiles.yml` prod target)
- `DBT_BIGQUERY_KEYFILE` env var není nastavena
- Elementary models nebyly spuštěny (`dbt run --select elementary`)
- Test results chybí v `stocks_dev_elementary` dataset

**Fix:**
1. Verify `elementary` profile má `prod` target v `profiles.yml`
2. Check `DBT_BIGQUERY_KEYFILE` env var je exported v workflow (transform-data, Step 4)
3. Verify Elementary dataset existuje: `stocks_dev_elementary` v BigQuery
4. Run `dbt test` lokálně pro populate test results

### Problem: Deploy-docs failuje s permission error

**Symptom:** `Error: Action failed with "The process '/usr/bin/git' failed with exit code 128"`

**Fix:** ✅ Již vyřešeno použitím `actions/deploy-pages@v4` místo git push

**Verify workflow používá:**
```yaml
- uses: actions/deploy-pages@v4  # ✅ Správně
```

**NE:**
```yaml
- uses: peaceiris/actions-gh-pages@v4  # ❌ Deprecated (permission issues)
```

### Problem: Deployment úspěšný, ale stránka je stará

**Symptom:** GitHub Pages ukazuje starou verzi dokumentace

**Fix:**
1. Check deployment timestamp v workflow:
   ```
   Actions → Workflow run → deploy-docs → Deploy to GitHub Pages
   ```
2. Verify `page_url` output:
   ```
   environment.url: https://briza5.github.io/Signiture_project/
   ```
3. Hard refresh browser: `Ctrl+Shift+R`
4. Check browser DevTools → Network → Response headers:
   ```
   last-modified: <should be recent>
   ```

**GitHub Pages cache:**
- GitHub Pages CDN může cachovat až 10 minut
- Force refresh pomůže bypass browser cache, ale ne CDN cache

---

## Customization

### Change Documentation Structure

Edit workflow file: `.github/workflows/stocks-pipeline.yml`

**Example: Add subdirectories**
```bash
# In deploy-docs job, Step 2 (Prepare GitHub Pages content):
mkdir -p gh-pages/docs gh-pages/reports
cp -r docs/target/* gh-pages/docs/
cp docs/edr_target/elementary_report.html gh-pages/reports/elementary.html
```

**Result:**
- dbt docs: `https://briza5.github.io/Signiture_project/docs/`
- Elementary: `https://briza5.github.io/Signiture_project/reports/elementary.html`

### Add Custom Homepage

**Create custom index.html:**
```html
<!-- gh-pages/index.html -->
<!DOCTYPE html>
<html>
<head>
  <title>Stock Pipeline Documentation</title>
</head>
<body>
  <h1>Stock Market Data Pipeline</h1>
  <ul>
    <li><a href="dbt-docs/">dbt Documentation</a></li>
    <li><a href="elementary.html">Elementary Report</a></li>
  </ul>
</body>
</html>
```

**Modify workflow:**
```bash
# Rename dbt docs index.html before copy
mv docs/target/index.html docs/target/dbt-docs.html
# Create custom homepage
echo "<custom HTML>" > gh-pages/index.html
```

### Disable Elementary Report

Remove from workflow:
```yaml
# Comment out nebo delete:
# - name: Generate Elementary report
#   working-directory: ./transformation
#   run: edr report --profiles-dir . --profile-target prod
```

**Note:** deploy-docs job má fallback, takže deployment NEPŘERUŠÍ i bez Elementary reportu

---

## Artifacts & Storage

### Documentation Artifacts

**Artifact name:** `documentation`

**Contents:**
- `target/index.html` (~500KB)
- `target/manifest.json` (~200KB)
- `target/catalog.json` (~50KB)
- `target/graph.gpickle` (~20KB)
- `edr_target/elementary_report.html` (~2MB)

**Total size:** ~2.8MB

**Retention:** 30 days (configurable)

**Storage costs:** ✅ Free (GitHub Actions free tier: 500MB artifacts)

### Optimization: Remove compiled/ SQL

**Before:** ~50MB artifacts (s compiled SQL)
**After:** ~3MB artifacts (bez compiled SQL)

**Reasoning:**
- dbt docs nepotřebuje compiled SQL (jen pro debugging)
- Compiled SQL je dostupný v BigQuery (dbt models tam jsou materialized)
- Ušetření artifact storage space

---

## Monitoring & Maintenance

### Check Deployment Status

**Daily:**
1. Visit https://briza5.github.io/Signiture_project/
2. Verify "Last updated" timestamp (dbt docs homepage)
3. Check Elementary report freshness (latest test run date)

**Weekly:**
1. Review workflow execution summary:
   ```
   Actions → Workflows → Stock Market Data Pipeline → Runs
   ```
2. Check deployment success rate (should be ~100%)
3. Verify artifact sizes (should stay <5MB)

### Update Schedule

Deployment runs automaticky s pipeline:
- **Frequency:** Každý všední den (Monday-Friday)
- **Time:** 8:00 AM UTC = 9:00 CET (winter) / 10:00 CEST (summer)
- **Trigger:** Cron schedule v workflow

**No manual intervention needed** - dokumentace se auto-update s novými daty

---

## Security & Access Control

### Public Documentation

⚠️ **GitHub Pages jsou PUBLIC** pokud máte public repository

**Published content is visible to anyone:**
- ✅ dbt docs (model schemas, SQL logic)
- ✅ Elementary reports (test results, data quality metrics)

**What's NOT exposed:**
- ❌ Raw data values (jen metadata + aggregates)
- ❌ Credentials (secrets zůstávají v GitHub Secrets)
- ❌ Sensitive PII (pokud není v column descriptions)

### Private Documentation (Optional)

Pro **private repository**:
1. GitHub Pages automaticky respektuje repository permissions
2. Dokumentace accessible jen pro collaborators
3. Requires GitHub login

**Current setup:** Public repository → Public GitHub Pages

---

## Cost & Resource Usage

### GitHub Pages Limits

**Free tier:**
- ✅ 1GB storage
- ✅ 100GB bandwidth/měsíc
- ✅ 10 builds/hour

**Current usage:**
- Storage: ~3MB (dokumentace)
- Bandwidth: ~10MB/den (estimated)
- Builds: ~1/den (pipeline runs)

**Overhead:** ✅ Well within free tier limits

### GitHub Actions Minutes

Deployment adds minimal overhead:
- **deploy-docs job:** ~30 seconds
- **Total pipeline:** ~5-10 minut (včetně ingestion + transformation)

**Monthly usage:**
- ~220 min/měsíc (22 weekdays × 10 min)
- Free tier: 2000 min/měsíc
- **Overhead:** ✅ 11% of free tier

---

## Next Steps

Po successful GitHub Pages setup:

1. ✅ **Bookmark dokumentaci URLs** pro easy access
2. ✅ **Share odkazy** s team members (pokud public)
3. ✅ **Monitor Elementary reports** pro data quality issues
4. 🔄 **Customize homepage** (optional - add branding, navigation)
5. 🔄 **Add custom domain** (optional - Settings → Pages → Custom domain)
6. 🔄 **Enable HTTPS** (automatically enabled by GitHub Pages)

---

## Reference Links

### Live Documentation
- 🔗 [dbt Docs](https://briza5.github.io/Signiture_project/) - Data models + lineage
- 🔗 [Elementary Report](https://briza5.github.io/Signiture_project/elementary.html) - Data quality monitoring

### GitHub Resources
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [Deploying to GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

### dbt Resources
- [dbt Docs](https://docs.getdbt.com/docs/collaborate/documentation)
- [dbt docs generate](https://docs.getdbt.com/reference/commands/cmd-docs)

### Elementary Resources
- [Elementary CLI Commands](https://docs.elementary-data.com/oss/cli-commands)
- [Elementary Report](https://docs.elementary-data.com/oss/guides/generate-report-ui)

---

## Changelog

### 2026-02-15 - Initial Setup
- ✅ Enabled GitHub Pages deployment via Actions
- ✅ Automated dbt docs generation (`dbt docs generate`)
- ✅ Automated Elementary report generation (`edr report`)
- ✅ Created deploy-docs job with GitHub Pages API
- ✅ Added error handling for Elementary report failures
- ✅ Optimized artifacts (removed compiled/ SQL)
- ✅ Added .nojekyll for static HTML serving
