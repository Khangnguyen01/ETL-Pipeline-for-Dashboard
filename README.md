# 🚀 DBT ETL Pipeline for Analytics Dashboard

[![dbt](https://img.shields.io/badge/dbt-1.10.15-orange.svg)](https://www.getdbt.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-Enabled-blue.svg)](https://cloud.google.com/bigquery)
[![Airflow](https://img.shields.io/badge/Airflow-3.1.2-green.svg)](https://airflow.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

> **Modern data transformation pipeline using dbt, BigQuery, and Airflow for mobile game analytics. One-command Docker deployment.**

---

## 🎯 Quick Start (3 Steps)

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/Khangnguyen01/ETL-Pipeline-for-Dashboard.git
cd ETL-Pipeline-for-Dashboard
```

### 2️⃣ Add Your Secret Files

You need to create **2 files** (both are gitignored):

#### **A. `application_default_credentials.json`** (Required)
Your Google Cloud service account key:
```bash
# Download from GCP Console:
# IAM & Admin → Service Accounts → Create/Select Account → Keys → Add Key → JSON
```

Place the downloaded JSON file in the project root as:
```
ETL-Pipeline-for-Dashboard/
└── application_default_credentials.json  ← Put it here
```

#### **B. `.env`** (Optional - for custom settings)
```bash
# Create .env file for custom configuration
cat > .env << EOF
AIRFLOW_UID=50000
GCP_PROJECT_ID=your-project-id
EOF
```

### 3️⃣ Run Docker
```bash
# Start everything (Airflow + PostgreSQL + Redis)
docker-compose up -d

# Wait ~2 minutes for initialization, then access:
# Airflow UI: http://localhost:8080
# Username: airflow
# Password: airflow
```

**That's it!** 🎉 Your pipeline is ready.

---

## 📋 Table of Contents

- [What This Pipeline Does](#-what-this-pipeline-does)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Detailed Setup Guide](#-detailed-setup-guide)
- [Configuration](#-configuration)
- [Running the Pipeline](#-running-the-pipeline)
- [Project Structure](#-project-structure)
- [Development Guide](#-development-guide)
- [Troubleshooting](#-troubleshooting)

---

## 📊 What This Pipeline Does

This dbt project transforms raw Firebase Analytics data into business-ready tables:

### Data Flow
```
Firebase Analytics (Raw Events)
        ↓
BigQuery Raw Tables
        ↓
🔄 DBT Staging Layer (70+ models)
   • Clean & flatten nested JSON
   • Standardize event schemas
   • Filter & deduplicate
        ↓
🔄 DBT Mart Layer (7+ models)
   • Aggregate metrics
   • Create wide tables with pivots
   • Business logic calculations
        ↓
📊 Analytics Dashboard (Looker/Tableau)
```

### Key Metrics Generated
- 💰 **IAP Analytics**: Revenue, conversion rates, purchase flows
- 📱 **Ad Revenue**: Impressions, clicks, rewards by placement
- 🎮 **Level Analytics**: Win/loss rates, progression funnels
- 👥 **User Engagement**: Sessions, retention, cohorts
- 📈 **Time-Series**: Daily/weekly trends and forecasts

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   DOCKER ENVIRONMENT                     │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Airflow    │  │  PostgreSQL  │  │    Redis     │ │
│  │  Scheduler   │  │   (Metadata) │  │   (Broker)   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              DBT Transformations                    │ │
│  │  • 70+ Staging Models (Incremental)                │ │
│  │  • 7+ Mart Models (Aggregations)                   │ │
│  │  • Data Quality Tests (Elementary)                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
                          ↓
                   Google BigQuery
                          ↓
                  Analytics Dashboard
```

---

## ⚙️ Prerequisites

### Required
- ✅ **Docker** & **Docker Compose** ([Install Docker](https://docs.docker.com/get-docker/))
- ✅ **Google Cloud Project** with BigQuery API enabled
- ✅ **Service Account** with BigQuery permissions:
  - `BigQuery Data Editor`
  - `BigQuery Job User`
  - `BigQuery Read Session User`

### Optional (for local dbt development)
- 🐍 **Python 3.10+** (if you want to run dbt locally without Docker)
- 📝 **Git** (for version control)

---

## 🔧 Detailed Setup Guide

### Step 1: Get Your GCP Credentials

1. **Go to [Google Cloud Console](https://console.cloud.google.com)**

2. **Select your project** (or create a new one)

3. **Enable BigQuery API**:
   - Go to: APIs & Services → Library
   - Search for "BigQuery API"
   - Click "Enable"

4. **Create Service Account**:
   ```
   Navigation Menu → IAM & Admin → Service Accounts → Create Service Account
   
   Name: dbt-pipeline-service-account
   
   Grant Roles:
   ✓ BigQuery Data Editor
   ✓ BigQuery Job User
   ✓ BigQuery Read Session User
   ```

5. **Download JSON Key**:
   - Click on the created service account
   - Go to "Keys" tab
   - Click "Add Key" → "Create New Key" → "JSON"
   - Save the file

6. **Rename and place the file**:
   ```bash
   # Save the downloaded file as:
   application_default_credentials.json
   
   # Place it in the project root (same folder as docker-compose.yml)
   ```

### Step 2: Configure Your Project

#### Update `profiles.yml` with your GCP project ID:

```yaml
dbt_dev:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: YOUR_PROJECT_ID  # ← Change this to your GCP project ID
      dataset: dev
      location: US
      threads: 8
      timeout_seconds: 6000
      keyfile: /home/airflow/.config/gcloud/application_default_credentials.json
```

#### (Optional) Create `.env` file for custom settings:

```bash
# Create .env in project root
AIRFLOW_UID=50000
AIRFLOW_PROJ_DIR=.
GCP_PROJECT_ID=your-project-id
```

### Step 3: Launch the Pipeline

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f airflow-scheduler

# Access Airflow UI
# http://localhost:8080
# Username: airflow
# Password: airflow
```

### Step 4: Verify Setup

```bash
# Check running containers
docker-compose ps

# Should show:
# - airflow-webserver (port 8080)
# - airflow-scheduler
# - airflow-worker
# - airflow-apiserver
# - postgres (port 5432)
# - redis (port 6379)
```

---

## ⚙️ Configuration

### Files You Need to Configure

| File | Required | Description | Location |
|------|----------|-------------|----------|
| `application_default_credentials.json` | ✅ Yes | GCP service account key | Project root |
| `profiles.yml` | ✅ Yes | Update `project:` field | Project root |
| `.env` | ❌ Optional | Custom environment vars | Project root |

### Files Protected by `.gitignore`

These files are **NOT** pushed to GitHub:
- ❌ `application_default_credentials.json` (your credentials)
- ❌ `.env` (environment variables)
- ❌ `logs/` (runtime logs)
- ❌ `target/` (compiled dbt artifacts)
- ❌ `dbt_packages/` (dependencies)

---

## 🏃 Running the Pipeline

### Using Airflow (Recommended)

#### 1. **Incremental Run** (default - processes new data)
In Airflow UI, trigger the `dbt_pipeline` DAG with no config:
```json
{}
```

#### 2. **Backfill Specific Date Range**
Trigger with custom date range:
```json
{
  "start_date": "2025-01-01",
  "end_date": "2025-01-31",
  "backfill": "true"
}
```

#### 3. **Monitor Progress**
- **Airflow UI**: http://localhost:8080
- **Logs**: Check task logs in Airflow UI
- **Elementary Reports**: Generated in `edr_target/`

### Using dbt CLI (for development)

```bash
# Enter the Docker container
docker exec -it <container-name> bash

# Inside container:
cd /opt/airflow/dbt

# Run specific model
dbt run --select stg_session_start

# Run all staging models
dbt run --select staging.*

# Run all mart models
dbt run --select mart.*

# Full refresh (rebuild from scratch)
dbt run --select mart_iap --full-refresh

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

---

## 📁 Project Structure

```
dbt_dev/
├── 📄 README.md                          # This file
├── 📄 CONFIGURATION_GUIDE.md             # Detailed setup instructions
├── 📄 docker-compose.yml                 # Docker orchestration
├── 📄 Dockerfile                         # Custom Airflow image
├── 📄 dbt_project.yml                    # dbt configuration
├── 📄 profiles.yml                       # dbt connection (UPDATE THIS)
├── 📄 profiles.yml.example               # Template
├── 📄 requirements.txt                   # Python dependencies
├── 📄 packages.yml                       # dbt packages
│
├── 🔒 application_default_credentials.json  # GCP key (YOU ADD THIS)
├── 🔒 .env                                   # Environment vars (OPTIONAL)
│
├── 📂 models/                            # dbt models
│   ├── 📂 staging/                       # 70+ staging models
│   │   ├── stg_session_start.sql
│   │   ├── stg_iap_purchased.sql
│   │   ├── stg_ad_impression.sql
│   │   └── ...
│   ├── 📂 mart/                          # Business logic models
│   │   ├── mart_iap.sql                  # IAP analytics
│   │   ├── mart_firebase.sql             # Firebase events
│   │   ├── mart_level_analyst.sql        # Level progression
│   │   ├── mart_overview.sql             # Summary metrics
│   │   └── ...
│   └── 📂 monitoring/                    # Data quality checks
│
├── 📂 macros/                            # Jinja macros
│   ├── helpers.sql                       # Utility functions
│   ├── 📂 staging/                       # Staging macros
│   └── 📂 mart/                          # Mart macros
│
├── 📂 dags/                              # Airflow DAGs
│   ├── dbt_pipeline.py                   # Main pipeline
│   └── dbt_test.py                       # Test pipeline
│
├── 📂 tests/                             # dbt tests
├── 📂 seeds/                             # CSV seed files
├── 📂 config/                            # Airflow config
│
└── 📂 Generated (gitignored)/
    ├── target/                           # Compiled SQL
    ├── dbt_packages/                     # Installed packages
    ├── logs/                             # Runtime logs
    └── edr_target/                       # Elementary reports
```

---

## 💻 Development Guide

### Local Development (Without Docker)

If you prefer to develop locally:

```bash
# 1. Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Install dbt packages
dbt deps

# 4. Configure profiles.yml in ~/.dbt/profiles.yml
# (See profiles.yml.example for template)

# 5. Test connection
dbt debug

# 6. Run models
dbt run --select staging.*
```

### Adding New Staging Model

1. Create SQL file in `models/staging/`:
```sql
-- stg_new_event.sql
{{ config(
    materialized='incremental',
    unique_key=['user_pseudo_id_hashed', 'event_date', 'event_timestamp'],
    partition_by={'field': 'event_date', 'data_type': 'date'}
) }}

SELECT
    user_pseudo_id_hashed,
    event_date,
    event_timestamp,
    -- Add your transformations
FROM {{ source('firebase', 'raw_events') }}
WHERE event_name = 'new_event'
{% if is_incremental() %}
    AND event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}
```

2. Test:
```bash
dbt run --select stg_new_event
dbt test --select stg_new_event
```

### Adding New Mart Model

Update `dbt_project.yml` and use provided macros:
```yaml
vars:
  mart_firebase:
    events:
      - name: new_event
        has_pivot: true
        pivot_field: event_param_key
        value_fields: ['event_timestamp']
        agg_functions: ['COUNT']
```

---

## 🐛 Troubleshooting

### Issue: Docker containers won't start

**Solution:**
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose down
docker-compose up -d
```

### Issue: Permission denied on application_default_credentials.json

**Solution:**
```bash
# Fix file permissions
chmod 600 application_default_credentials.json
```

### Issue: BigQuery authentication failed

**Solution:**
1. Verify service account has correct roles
2. Check `project:` in `profiles.yml` matches your GCP project
3. Ensure JSON key file is valid:
   ```bash
   cat application_default_credentials.json | python -m json.tool
   ```

### Issue: dbt compilation error

**Solution:**
```bash
# Enter container
docker exec -it <container-id> bash

# Clear cache
dbt clean
dbt deps
dbt compile
```

### Issue: Airflow DAG not showing

**Solution:**
1. Check DAG file syntax: `python dags/dbt_pipeline.py`
2. Check scheduler logs: `docker-compose logs airflow-scheduler`
3. Refresh in Airflow UI

### Issue: Out of memory

**Solution:**
```bash
# Increase Docker memory in Docker Desktop settings
# Settings → Resources → Memory (increase to 8GB+)
```

---

## 📚 Project Features

### ✨ Highlights

- **🚀 One-Command Deployment**: Just `docker-compose up -d`
- **📦 Pre-configured Airflow**: Scheduler, worker, and webserver ready
- **🔄 Incremental Processing**: Efficient date-partitioned transformations
- **📊 Data Quality**: Built-in Elementary Data monitoring
- **🎯 Game Analytics**: Pre-built IAP, Ad, Level, Engagement models
- **🔧 Customizable**: Easy to add new events and metrics
- **📖 Auto-Documentation**: `dbt docs generate` for lineage graphs

### 🎮 Supported Events (70+)

- Session & Engagement
- IAP Purchases & Flows
- Ad Impressions & Revenue
- Level Progression
- In-App Features
- User Retention
- And many more...

---

## 📞 Support & Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

## 📄 License

This project is private and proprietary.

---

## 👥 Contributors

**Data Engineering Team**

---

## 🎉 Getting Started Checklist

- [ ] Docker and Docker Compose installed
- [ ] GCP service account created with BigQuery permissions
- [ ] `application_default_credentials.json` downloaded and placed in project root
- [ ] `profiles.yml` updated with your GCP project ID
- [ ] Run `docker-compose up -d`
- [ ] Access Airflow at http://localhost:8080 (airflow/airflow)
- [ ] Trigger `dbt_pipeline` DAG
- [ ] Check task logs for success
- [ ] View generated reports in `edr_target/`

---

**Ready to transform your data! 🚀**

