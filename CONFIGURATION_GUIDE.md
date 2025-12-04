# 🔧 Configuration Guide

This document provides step-by-step instructions for configuring the dbt project.

---

## 🚀 Docker Setup (Recommended)

**For most users, you only need:**
1. ✅ Docker Desktop installed
2. ✅ `application_default_credentials.json` (GCP service account key)
3. ✅ Update `project:` in `profiles.yml`
4. ✅ Run `docker-compose up -d`

**See [QUICKSTART.md](./QUICKSTART.md) for 3-step setup!**

---

## 📋 Quick Configuration Checklist

### Docker Setup (Recommended)
- [ ] Install Docker Desktop
- [ ] Add `application_default_credentials.json`
- [ ] Update `profiles.yml` with GCP project ID
- [ ] (Optional) Create `.env` file
- [ ] Run `docker-compose up -d`

### Local Development Setup (Optional)
- [ ] Install Python dependencies
- [ ] Set up Google Cloud credentials
- [ ] Configure `~/.dbt/profiles.yml`
- [ ] Install dbt packages
- [ ] Test connection

---

## 1️⃣ Install Python Dependencies

```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Mac/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

## 2️⃣ Google Cloud Setup

### Option A: OAuth (Recommended for Local Development)

```bash
# Install gcloud CLI if not already installed
# Download from: https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Option B: Service Account (Recommended for Production)

1. **Create Service Account:**
   - Go to [GCP Console](https://console.cloud.google.com)
   - Navigate to: IAM & Admin → Service Accounts
   - Click "Create Service Account"
   - Grant roles:
     - `BigQuery Data Editor`
     - `BigQuery Job User`
     - `BigQuery Read Session User`

2. **Download Key:**
   - Click on the service account
   - Keys → Add Key → Create New Key → JSON
   - Save as `application_default_credentials.json`

3. **⚠️ IMPORTANT:** Add to `.gitignore` (already done)

---

## 3️⃣ Configure dbt Profiles

### Create `profiles.yml` in your home directory:

**Location:**
- Windows: `C:\Users\YourUsername\.dbt\profiles.yml`
- Mac/Linux: `~/.dbt/profiles.yml`

### Template:

```yaml
dbt_dev:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth  # or service-account
      project: YOUR_GCP_PROJECT_ID  # ← CHANGE THIS
      dataset: dev                   # ← Or your dev dataset
      location: US
      threads: 8
      timeout_seconds: 6000
      job_retries: 1
      priority: interactive
      
      # If using service account, uncomment:
      # keyfile: /absolute/path/to/application_default_credentials.json
      
    prod:
      type: bigquery
      method: service-account
      project: YOUR_GCP_PROJECT_ID  # ← CHANGE THIS
      dataset: prod                  # ← Or your prod dataset
      location: US
      threads: 8
      timeout_seconds: 6000
      keyfile: /absolute/path/to/application_default_credentials.json
      priority: interactive
```

### Update These Fields:

| Field | Description | Example |
|-------|-------------|---------|
| `project` | Your GCP project ID | `my-analytics-project` |
| `dataset` | Target BigQuery dataset | `dev`, `staging`, `prod` |
| `keyfile` | Path to service account JSON | `/home/user/.config/gcloud/key.json` |
| `location` | BigQuery region | `US`, `EU`, `asia-northeast1` |

---

## 4️⃣ Update dbt_project.yml

Open `dbt_project.yml` and verify/update:

```yaml
name: 'dbt_dev'  # Keep as is
version: '1.0.0'
profile: 'dbt_dev'  # Must match profiles.yml

# Update dataset schemas if needed
models:
  dbt_dev:
    staging:
        +materialized: incremental
        +schema: "staging"  # ← Change if needed
    mart:
        +materialized: table
        +schema: "mart"     # ← Change if needed
    monitoring:
      +schema: monitoring   # ← Change if needed
```

---

## 5️⃣ Install dbt Packages

```bash
dbt deps
```

This will install:
- `dbt-utils` (utility macros)
- `audit_helper` (data auditing)
- `elementary` (data quality monitoring)

---

## 6️⃣ Test Connection

```bash
dbt debug
```

**Expected Output:**
```
Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
 - git [OK found]

Connection:
  method: oauth
  database: your-project
  schema: dev
  location: US
  priority: interactive
  
Connection test: [OK connection ok]
```

If you see errors, check:
- [ ] `profiles.yml` location and syntax
- [ ] GCP authentication (`gcloud auth list`)
- [ ] Project ID matches GCP console
- [ ] Service account has correct permissions

---

## 7️⃣ (Optional) Configure Airflow

### For Docker/Airflow Setup:

1. **Copy credentials:**
   ```bash
   # Place your service account key as:
   application_default_credentials.json
   ```

2. **Create `.env` file:**
   ```bash
   # Copy template
   cp .env.example .env  # If template exists
   
   # Or create manually:
   cat > .env << EOF
   AIRFLOW_UID=50000
   AIRFLOW_PROJ_DIR=.
   GCP_PROJECT_ID=your-project-id
   EOF
   ```

3. **Start Airflow:**
   ```bash
   docker-compose up -d
   ```

4. **Access UI:**
   - URL: http://localhost:8080
   - Default credentials: `airflow` / `airflow`

---

## 8️⃣ First Run Test

```bash
# Compile models (check SQL syntax)
dbt compile

# Run a simple staging model
dbt run --select stg_session_start

# Run all staging models
dbt run --select staging.*

# Test data quality
dbt test --select stg_session_start
```

---

## 🔐 Security Best Practices

### ⚠️ NEVER COMMIT:

- ❌ `application_default_credentials.json`
- ❌ `profiles.yml` (if it contains credentials)
- ❌ `.env` files
- ❌ Any `*-key.json` files
- ❌ SSH keys or tokens

### ✅ DO COMMIT:

- ✅ `profiles.yml.example` (template without credentials)
- ✅ `dbt_project.yml`
- ✅ `.gitignore`
- ✅ `README.md`
- ✅ Model SQL files
- ✅ Macros and tests

---

## 🆘 Troubleshooting

### Error: "Could not find profile named 'dbt_dev'"

**Solution:**
- Check `profiles.yml` exists in `~/.dbt/` directory
- Verify `profile:` in `dbt_project.yml` matches profile name in `profiles.yml`

### Error: "Invalid service account JSON"

**Solution:**
```bash
# Verify JSON is valid
cat application_default_credentials.json | python -m json.tool

# Check file permissions
chmod 600 application_default_credentials.json
```

### Error: "Permission denied on BigQuery"

**Solution:**
- Grant service account these roles:
  - BigQuery Data Editor
  - BigQuery Job User
  - BigQuery Read Session User

### Error: "Compilation error in macro"

**Solution:**
```bash
# Clear cache and recompile
dbt clean
dbt deps
dbt compile
```

---

## 📞 Need Help?

1. Check [README.md](./README.md) for detailed documentation
2. Review [dbt Documentation](https://docs.getdbt.com/)
3. Contact data engineering team

---

**Good luck with your setup! 🚀**

