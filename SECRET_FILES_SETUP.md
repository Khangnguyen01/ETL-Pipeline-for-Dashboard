# 🔒 Secret Files Setup Guide

This guide shows you exactly which files you need to add before running Docker.

---

## 📁 Required Files Checklist

After cloning the repository, you need to add these files:

```
ETL-Pipeline-for-Dashboard/
│
├── 📂 dags/                             ✅ Already in repo
├── 📂 models/                           ✅ Already in repo
├── 📂 macros/                           ✅ Already in repo
├── 📄 docker-compose.yml                ✅ Already in repo
├── 📄 profiles.yml                      ⚠️  UPDATE THIS
│
├── 🔒 application_default_credentials.json   ❌ YOU MUST ADD
└── 🔒 .env                                    🟡 OPTIONAL
```

---

## 1️⃣ Required: GCP Service Account Key

### File: `application_default_credentials.json`

**📍 Location:** Project root (same folder as `docker-compose.yml`)

**🎯 Purpose:** Authenticates your pipeline with Google BigQuery

**📥 How to Get This File:**

#### Step 1: Go to Google Cloud Console
👉 https://console.cloud.google.com

#### Step 2: Navigate to Service Accounts
```
☰ Navigation Menu 
  → IAM & Admin 
    → Service Accounts
```

#### Step 3: Create or Select Service Account
**Option A - Create New:**
```
1. Click "CREATE SERVICE ACCOUNT"
2. Name: dbt-pipeline-service
3. Description: Service account for dbt ETL pipeline
4. Click "CREATE AND CONTINUE"
```

**Option B - Use Existing:**
```
Select an existing service account that has BigQuery access
```

#### Step 4: Grant Required Roles
Select these roles:
- ✅ `BigQuery Data Editor`
- ✅ `BigQuery Job User`
- ✅ `BigQuery Read Session User`

Click "CONTINUE" → "DONE"

#### Step 5: Download JSON Key
```
1. Click on the service account name
2. Go to "KEYS" tab
3. Click "ADD KEY" → "Create new key"
4. Select "JSON"
5. Click "CREATE"
```

A JSON file will download automatically.

#### Step 6: Rename and Place File
```bash
# Rename the downloaded file to:
application_default_credentials.json

# Move it to project root:
ETL-Pipeline-for-Dashboard/
└── 🔒 application_default_credentials.json  ← HERE
```

**✅ File Should Look Like:**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "dbt-pipeline@your-project.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

---

## 2️⃣ Required: Update profiles.yml

### File: `profiles.yml`

**📍 Location:** Project root

**🎯 Purpose:** Tells dbt which BigQuery project to use

**✏️ What to Change:**

Open `profiles.yml` and update line 7:

```yaml
dbt_dev:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: wool-away  # ← CHANGE THIS to your GCP project ID
      dataset: dev
      location: US
      threads: 8
      timeout_seconds: 6000
      keyfile: /home/airflow/.config/gcloud/application_default_credentials.json
```

**📝 Find Your Project ID:**
1. Go to [GCP Console](https://console.cloud.google.com)
2. Look at the top bar - your project name is displayed
3. Click the dropdown → copy the "Project ID" (not "Project Name")

Example:
```
Project Name: My Analytics Project
Project ID: my-analytics-123456  ← Use this one
```

---

## 3️⃣ Optional: Environment Variables

### File: `.env`

**📍 Location:** Project root

**🎯 Purpose:** Custom configuration (most defaults work fine)

**📋 When You Need This:**
- You want to change Airflow port (default: 8080)
- You want to customize database passwords
- You need specific environment variables

**📝 How to Create:**

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
nano .env
```

**Example `.env`:**
```bash
# Required
AIRFLOW_UID=50000
GCP_PROJECT_ID=my-analytics-123456

# Optional (defaults work fine)
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
```

**Most users don't need this file!** The defaults work great.

---

## ✅ Final File Structure

After setup, you should have:

```
ETL-Pipeline-for-Dashboard/
│
├── 🔒 application_default_credentials.json  ✅ Added by you
├── 📄 profiles.yml                          ✅ Updated by you
├── 🔒 .env                                  🟡 Optional
│
├── 📄 docker-compose.yml                    ✅ From repo
├── 📄 Dockerfile                            ✅ From repo
├── 📄 dbt_project.yml                       ✅ From repo
├── 📄 requirements.txt                      ✅ From repo
├── 📄 packages.yml                          ✅ From repo
│
├── 📂 dags/                                 ✅ From repo
├── 📂 models/                               ✅ From repo
├── 📂 macros/                               ✅ From repo
├── 📂 tests/                                ✅ From repo
└── ...
```

---

## 🚀 Ready to Launch!

Once you have:
- ✅ `application_default_credentials.json` in project root
- ✅ `profiles.yml` updated with your project ID

**Run:**
```bash
docker-compose up -d
```

**Then access:**
- Airflow UI: http://localhost:8080
- Login: `airflow` / `airflow`

---

## 🔒 Security Reminders

### ✅ DO:
- ✅ Keep `application_default_credentials.json` secure
- ✅ Set file permissions: `chmod 600 application_default_credentials.json`
- ✅ Add it to `.gitignore` (already done)
- ✅ Never commit credentials to Git

### ❌ DON'T:
- ❌ Share your credentials file
- ❌ Commit it to Git (it's gitignored)
- ❌ Email it or post it online
- ❌ Store it in public locations

---

## 🆘 Troubleshooting

### ❌ "File not found: application_default_credentials.json"
**Solution:** Make sure file is in project root, same folder as `docker-compose.yml`
```bash
ls -la application_default_credentials.json
```

### ❌ "Permission denied"
**Solution:** Fix file permissions
```bash
chmod 600 application_default_credentials.json
```

### ❌ "Invalid JSON"
**Solution:** Re-download the key from GCP Console - file may be corrupted

### ❌ "Project not found"
**Solution:** Update `project:` in `profiles.yml` with correct GCP project ID

### ❌ "Access denied to BigQuery"
**Solution:** Service account needs these roles:
- BigQuery Data Editor
- BigQuery Job User
- BigQuery Read Session User

---

## 📚 Next Steps

1. ✅ Added secret files
2. ✅ Updated profiles.yml
3. 👉 See [QUICKSTART.md](./QUICKSTART.md) to launch Docker
4. 👉 See [README.md](./README.md) for full documentation

---

**Questions?** Check [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md) for more details.

