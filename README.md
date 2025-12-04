# 🚀 DBT ETL Pipeline for Analytics Dashboard

[![dbt](https://img.shields.io/badge/dbt-1.10.15-orange.svg)](https://www.getdbt.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-Enabled-blue.svg)](https://cloud.google.com/bigquery)
[![Airflow](https://img.shields.io/badge/Airflow-3.1.0-green.svg)](https://airflow.apache.org/)
[![Elementary](https://img.shields.io/badge/Elementary-0.20.0-purple.svg)](https://www.elementary-data.com/)

> **Modern data transformation pipeline using dbt, BigQuery, and Airflow for mobile game analytics**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration Setup](#-configuration-setup)
- [Project Structure](#-project-structure)
- [Running the Pipeline](#-running-the-pipeline)
- [Development](#-development)
- [Monitoring & Testing](#-monitoring--testing)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Overview

This dbt project transforms raw Firebase Analytics data from a mobile game into actionable insights through a multi-layered data warehouse architecture:

- **Staging Layer** (`stg_*`): Raw data cleaning and standardization (70+ staging models)
- **Mart Layer** (`mart_*`): Business logic aggregations and wide tables
- **Monitoring Layer**: Data quality checks and pipeline monitoring

### Key Features

✨ **Incremental Processing** - Efficient date-partitioned transformations  
🔄 **Backfill Support** - Flexible date range processing via Airflow  
📊 **Wide Table Generation** - Dynamic pivot tables from event configurations  
🎮 **Game-Specific Metrics** - IAP, Ad Revenue, Level Analytics, Engagement  
🔍 **Data Quality Monitoring** - Elementary Data integration  
🐳 **Docker Support** - Containerized Airflow orchestration  

---

## 🏗️ Architecture

```
┌─────────────────┐
│ Firebase        │
│ Analytics (Raw) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ BigQuery        │
│ Raw Tables      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ DBT Staging     │◄─── Flatten nested JSON
│ (70+ models)    │     Clean & standardize
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ DBT Mart        │◄─── Pivot & aggregate
│ (7+ models)     │     Business metrics
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Dashboard       │
│ (Looker/Tableau)│
└─────────────────┘
```

---

## ⚙️ Prerequisites

- **Python** 3.10+ (3.11 recommended)
- **Google Cloud Account** with BigQuery enabled
- **Docker & Docker Compose** (for Airflow orchestration)
- **Git** for version control

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Khangnguyen01/ETL-Pipeline-for-Dashboard.git
cd dbt_dev
```

### 2. Install Dependencies

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dbt and dependencies
pip install -r requirements.txt
```

### 3. Install dbt Packages

```bash
dbt deps
```

### 4. Configure Your Environment

See [Configuration Setup](#-configuration-setup) below for detailed instructions.

### 5. Test Connection

```bash
dbt debug
```

---

## 🔧 Configuration Setup

### 📝 Files You Need to Configure (NOT in Git)

The following files contain sensitive information and should be configured locally:

#### 1. **`profiles.yml`** - dbt Connection Profile

Create or update `~/.dbt/profiles.yml` (user home directory):

```yaml
dbt_dev:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth  # or service-account
      project: your-gcp-project-id
      dataset: dev
      location: US
      threads: 8
      timeout_seconds: 6000
      job_retries: 1
      priority: interactive
      # For OAuth (recommended for local development):
      keyfile: /path/to/your/service-account-key.json  # Optional
      
    prod:
      type: bigquery
      method: service-account
      project: your-gcp-project-id
      dataset: prod
      location: US
      threads: 8
      keyfile: /path/to/your/service-account-key.json
```

**Configuration Options:**

- **OAuth Method** (Local Development):
  ```bash
  gcloud auth application-default login
  ```
  Then set `method: oauth` in profiles.yml

- **Service Account Method** (Production):
  1. Download service account key from GCP Console
  2. Set `method: service-account`
  3. Set `keyfile: /path/to/key.json`

#### 2. **`application_default_credentials.json`** - GCP Credentials

**⚠️ DO NOT COMMIT THIS FILE**

- **For Local Development:**
  ```bash
  gcloud auth application-default login
  ```
  Credentials will be stored at:
  - Windows: `%APPDATA%\gcloud\application_default_credentials.json`
  - Mac/Linux: `~/.config/gcloud/application_default_credentials.json`

- **For Docker/Airflow:**
  1. Download service account key from GCP
  2. Place in project root as `application_default_credentials.json`
  3. Update `docker-compose.yml` volume mount:
     ```yaml
     volumes:
       - ./application_default_credentials.json:/home/airflow/.config/gcloud/application_default_credentials.json:ro
     ```

#### 3. **`.env`** (Optional) - Environment Variables

Create `.env` file for Airflow configuration:

```env
# Airflow Configuration
AIRFLOW_UID=50000
AIRFLOW_PROJ_DIR=.
AIRFLOW_IMAGE_NAME=apache/airflow:3.1.0

# Database
POSTGRES_USER=airflow
POSTGRES_PASSWORD=your-secure-password
POSTGRES_DB=airflow

# BigQuery
GCP_PROJECT_ID=your-gcp-project-id
```

#### 4. **`dbt_project.yml`** - Project Configuration

Update project-specific settings:

```yaml
name: 'dbt_dev'
version: '1.0.0'
profile: 'dbt_dev'

# Update these based on your requirements
models:
  dbt_dev:
    staging:
        +materialized: incremental
        +schema: "staging"
        +partition_by:
          field: event_date
          data_type: date
    mart:
        +materialized: table
        +schema: "mart"
        +partition_by:
          field: event_date
          data_type: date

vars:
  mart_config:
    target_date_column: event_date
  # Add your custom variables here
```

---

## 📁 Project Structure

```
dbt_dev/
├── 📄 README.md                          # This file
├── 📄 dbt_project.yml                    # dbt project configuration
├── 📄 profiles.yml                       # dbt connection profile (DO NOT COMMIT)
├── 📄 packages.yml                       # dbt package dependencies
├── 📄 requirements.txt                   # Python dependencies
├── 📄 docker-compose.yml                 # Airflow orchestration
├── 📄 application_default_credentials.json  # GCP credentials (DO NOT COMMIT)
│
├── 📂 models/                            # dbt models
│   ├── 📂 staging/                       # 70+ staging models
│   │   ├── stg_session_start.sql
│   │   ├── stg_iap_purchased.sql
│   │   ├── stg_ad_impression.sql
│   │   └── ...
│   ├── 📂 mart/                          # Business logic models
│   │   ├── mart_iap.sql                  # IAP analytics
│   │   ├── mart_firebase.sql             # Firebase events wide table
│   │   ├── mart_level_analyst.sql        # Level progression
│   │   └── ...
│   └── 📂 monitoring/                    # Data quality checks
│
├── 📂 macros/                            # Jinja macros
│   ├── helpers.sql                       # Utility functions
│   ├── 📂 staging/                       # Staging layer macros
│   └── 📂 mart/                          # Mart layer macros
│
├── 📂 dags/                              # Airflow DAGs
│   ├── dbt_pipeline.py                   # Main pipeline DAG
│   └── dbt_test.py                       # Test pipeline
│
├── 📂 tests/                             # dbt tests
├── 📂 seeds/                             # CSV seed files
├── 📂 snapshots/                         # SCD Type 2 snapshots
├── 📂 analyses/                          # Ad-hoc queries
│
├── 📂 target/                            # Compiled SQL (ignored)
├── 📂 dbt_packages/                      # Installed packages (ignored)
└── 📂 logs/                              # dbt logs (ignored)
```

---

## 🏃 Running the Pipeline

### Local Development

#### 1. **Compile Models** (Check SQL syntax)

```bash
dbt compile
```

#### 2. **Run Specific Model**

```bash
# Run single model
dbt run --select stg_session_start

# Run all staging models
dbt run --select staging.*

# Run all mart models
dbt run --select mart.*
```

#### 3. **Full Refresh** (Rebuild from scratch)

```bash
dbt run --select mart_iap --full-refresh
```

#### 4. **Test Data Quality**

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select stg_session_start
```

#### 5. **Generate Documentation**

```bash
dbt docs generate
dbt docs serve
```

### Production (Airflow)

#### 1. **Start Airflow**

```bash
docker-compose up -d
```

Access Airflow UI at: `http://localhost:8080`

#### 2. **Run Pipeline**

**Incremental Run (Default):**
```json
// Trigger DAG with default config (yesterday's data)
{}
```

**Backfill Specific Date Range:**
```json
{
  "start_date": "2025-01-01",
  "end_date": "2025-01-31",
  "backfill": "true"
}
```

#### 3. **Monitor Pipeline**

- Airflow UI: `http://localhost:8080`
- Elementary Reports:
  ```bash
  edr monitor --profiles-dir . --project-dir .
  ```

---

## 💻 Development

### Adding New Staging Model

1. Create SQL file in `models/staging/`:
   ```sql
   -- stg_new_event.sql
   {{ config(
       materialized='incremental',
       unique_key=['user_pseudo_id_hashed', 'event_date', 'event_timestamp'],
       partition_by={'field': 'event_date', 'data_type': 'date'},
       cluster_by=['user_pseudo_id_hashed']
   ) }}
   
   SELECT
       user_pseudo_id_hashed,
       event_date,
       event_timestamp,
       event_name,
       -- Add your transformations
   FROM {{ source('firebase', 'raw_events') }}
   WHERE event_name = 'new_event'
   {% if is_incremental() %}
       AND event_date > (SELECT MAX(event_date) FROM {{ this }})
   {% endif %}
   ```

2. Add to `sources.yml` if needed

3. Test:
   ```bash
   dbt run --select stg_new_event
   dbt test --select stg_new_event
   ```

### Adding New Mart Model

1. Add configuration to `dbt_project.yml`:
   ```yaml
   vars:
     mart_firebase:
       events:
         - name: new_event
           has_pivot: true
           pivot_field: event_param_key
           value_fields: ['event_timestamp', 'event_value']
           agg_functions: ['COUNT', 'SUM']
   ```

2. Use macro in mart model:
   ```sql
   {{ generate_wide_table_for_firebase(event_config, ...) }}
   ```

### Using Custom Macros

See `macros/helpers.sql` and `macros/mart/` for available utilities:

- `generate_wide_table_for_firebase()` - Create pivot tables
- `generate_wide_table_for_event()` - Multi-pivot event tables
- Date/time utilities, string functions, etc.

---

## 🔍 Monitoring & Testing

### Elementary Data Quality

```bash
# Run tests and generate report
dbt test
edr monitor --profiles-dir . --project-dir .

# View report
open edr_target/elementary_report.html
```

### dbt Tests

```bash
# All tests
dbt test

# Specific model tests
dbt test --select stg_iap_purchased

# Only data tests (not schema)
dbt test --exclude test_type:schema
```

### Logs

- **dbt logs**: `logs/dbt.log`
- **Airflow logs**: `logs/dag_id=dbt_pipeline/`
- **Elementary logs**: `edr_target/edr.log`

---

## 🐛 Troubleshooting

### Issue: `KeyError: 'dbt_dev://macros\\helpers.sql'`

**Solution:**
```bash
dbt clean
dbt deps
dbt compile
```

### Issue: Permission Denied on Git Push

**Solution:**
```bash
# Use SSH instead of HTTPS
git remote set-url origin git@github.com:Khangnguyen01/ETL-Pipeline-for-Dashboard.git

# Or configure Git credentials
git config credential.helper store
```

### Issue: BigQuery Authentication Failed

**Solution:**
```bash
# Re-authenticate
gcloud auth application-default login

# Or check service account key path in profiles.yml
```

### Issue: Model Compilation Error

**Solution:**
```bash
# Check syntax
dbt compile --select problematic_model

# Run with debug
dbt --debug run --select problematic_model
```

### Issue: Airflow DAG Not Showing

**Solution:**
1. Check DAG file syntax: `python dags/dbt_pipeline.py`
2. Check Airflow logs: `docker-compose logs airflow-scheduler`
3. Refresh DAG: Click refresh button in Airflow UI

---

## 📚 Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Elementary Data](https://docs.elementary-data.com/)

---

## 📄 License

This project is private and proprietary.

---

## 👥 Contributors

- **Data Engineering Team**
- **Analytics Team**

---

## 📮 Contact

For questions or support, please contact the data engineering team.

---

**Happy Data Transforming! 🎉**

