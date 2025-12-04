# ⚡ Quick Start Guide

**Get your pipeline running in 3 minutes!**

---

## 📦 What You Need

1. ✅ Docker Desktop installed ([Download here](https://www.docker.com/products/docker-desktop))
2. ✅ Google Cloud service account JSON key

---

## 🚀 3-Step Setup

### Step 1: Clone & Navigate
```bash
git clone https://github.com/Khangnguyen01/ETL-Pipeline-for-Dashboard.git
cd ETL-Pipeline-for-Dashboard
```

### Step 2: Add Your Secrets

Create **ONE file**: `application_default_credentials.json`

```
📁 ETL-Pipeline-for-Dashboard/
   ├── dags/
   ├── models/
   ├── docker-compose.yml
   └── 🔒 application_default_credentials.json  ← PUT YOUR GCP KEY HERE
```

**How to get this file:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate: **IAM & Admin** → **Service Accounts**
3. Create/Select account with these roles:
   - `BigQuery Data Editor`
   - `BigQuery Job User` 
   - `BigQuery Read Session User`
4. Click **Keys** → **Add Key** → **Create New Key** → **JSON**
5. Download and rename it to `application_default_credentials.json`
6. Place in project root

### Step 3: Launch!
```bash
docker-compose up -d
```

**That's it!** 🎉

Wait 2-3 minutes for initialization, then:
- **Airflow UI**: http://localhost:8080
- **Login**: `airflow` / `airflow`

---

## 🎯 First Pipeline Run

1. Open http://localhost:8080
2. Login: `airflow` / `airflow`
3. Find DAG: `dbt_pipeline`
4. Click **▶ Trigger DAG**
5. Watch it run! ✨

---

## ⚙️ Configuration (Optional)

### Update Your GCP Project ID

Edit `profiles.yml` (line 7):
```yaml
project: wool-away  # ← Change to YOUR-PROJECT-ID
```

### Custom Environment Variables

Create `.env` file (optional):
```bash
AIRFLOW_UID=50000
GCP_PROJECT_ID=your-project-id
```

---

## 📊 What Gets Created

After successful run, check BigQuery:
- **Dataset**: `dev`
  - **Schema**: `staging` (70+ tables)
  - **Schema**: `mart` (7+ tables)

---

## 🔍 Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f airflow-scheduler

# Check status
docker-compose ps

# Enter container
docker exec -it <container-name> bash

# Inside container - run dbt manually
cd /opt/airflow/dbt
dbt run --select staging.*
```

---

## 🐛 Quick Troubleshooting

### ❌ Error: "Permission denied"
```bash
chmod 600 application_default_credentials.json
```

### ❌ Error: "Project not found"
Update `profiles.yml` with correct GCP project ID

### ❌ Error: "Docker won't start"
- Open Docker Desktop
- Increase memory to 8GB+ (Settings → Resources)

### ❌ Error: "DAG not showing"
Wait 2-3 minutes for initialization, then refresh browser

---

## 📚 Need More Details?

- **Full Documentation**: See [README.md](./README.md)
- **Configuration Guide**: See [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md)
- **Troubleshooting**: See README.md → Troubleshooting section

---

## ✅ Success Checklist

- [ ] Docker Desktop running
- [ ] `application_default_credentials.json` in project root
- [ ] `profiles.yml` has correct project ID
- [ ] `docker-compose up -d` succeeded
- [ ] http://localhost:8080 accessible
- [ ] Logged in as `airflow`/`airflow`
- [ ] `dbt_pipeline` DAG visible
- [ ] First DAG run successful ✨

---

**You're all set! Happy data transforming! 🎉**

