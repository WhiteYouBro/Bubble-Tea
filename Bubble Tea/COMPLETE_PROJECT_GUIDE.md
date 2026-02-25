# 🫖 Bubble Tea Shop - Complete Project Guide

**Comprehensive guide for installing, configuring, and running the entire project**

---

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [System Requirements](#-system-requirements)
3. [Installation](#-installation)
4. [Database Setup](#-database-setup)
5. [Monitoring Setup (Grafana + Prometheus)](#-monitoring-setup)
6. [Backup System (pgAgent)](#-backup-system)
7. [Running the Application](#-running-the-application)
8. [Features Overview](#-features-overview)
9. [Troubleshooting](#-troubleshooting)

---

## ⚡ Quick Start

### For experienced users:

```bash
# 1. Clone and navigate
cd "D:\POProject\Bubble Tea"

# 2. Create .env file
echo DB_HOST=localhost > .env
echo DB_PORT=5432 >> .env
echo DB_NAME=bibabobabebe >> .env
echo DB_USER=postgres >> .env
echo DB_PASSWORD=YOUR_PASSWORD >> .env

# 3. Setup database
cd database
quick_setup_db.bat

# 4. Create admin user
cd ..
python create_admin.py

# 5. Start monitoring
cd monitoring
docker-compose up -d

# 6. Setup pgAgent backups
# Run in pgAdmin: database\backup_scripts\create_pgagent_jobs.sql

# 7. Run Flask app
python app.py
```

**Access:**
- Website: http://localhost:5000
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- Backup Manager: http://localhost:5000/backup (admin only)

---

## 💻 System Requirements

### Software:
- **Python 3.8+** (Python 3.14 recommended)
- **PostgreSQL 17** with pgAgent extension
- **Docker Desktop** (for monitoring stack)
- **Git** (optional)

### Hardware:
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 10GB free space minimum
- **OS:** Windows 10/11

---

## 📥 Installation

### 1. Install PostgreSQL 17

1. Download from https://www.postgresql.org/download/windows/
2. During installation:
   - **Install pgAgent** (check the box in Stack Builder)
   - Set password for `postgres` user
   - Default port: 5432

3. Verify installation:
   ```powershell
   psql --version
   # Should output: psql (PostgreSQL) 17.x
   ```

### 2. Install Python

1. Download Python 3.14 from https://www.python.org/
2. ✅ Check "Add Python to PATH"
3. Verify:
   ```bash
   python --version
   # Should output: Python 3.14.x
   ```

### 3. Install Docker Desktop

1. Download from https://www.docker.com/products/docker-desktop
2. Install and restart computer
3. Start Docker Desktop
4. Verify:
   ```bash
   docker --version
   docker-compose --version
   ```

### 4. Clone/Download Project

```bash
cd D:\POProject
git clone <repository-url> "Bubble Tea"
# OR download and extract ZIP
```

---

## 🗄️ Database Setup

### Step 1: Create `.env` file

Create file `.env` in project root:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bibabobabebe
DB_USER=postgres
DB_PASSWORD=admin1235
```

**⚠️ Replace `admin1235` with YOUR PostgreSQL password!**

### Step 2: Quick Database Setup

```bash
cd "D:\POProject\Bubble Tea\database"
quick_setup_db.bat
```

This script will:
- ✅ Drop existing database (if any)
- ✅ Create fresh database
- ✅ Apply schema (tables, indexes, constraints)
- ✅ Seed sample data (products, categories)

### Step 3: Create Admin User

```bash
cd "D:\POProject\Bubble Tea"

# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create admin
python create_admin.py
```

**Admin credentials:**
- Username: `adminkey`
- Password: `adminpass123`

### Step 4: Verify Database

```bash
psql -U postgres -d bibabobabebe -c "\dt"
```

Expected tables:
- categories
- products
- users
- orders
- order_items
- customers
- employees

---

## 📊 Monitoring Setup

### Prerequisites
- Docker Desktop must be running

### Step 1: Start Monitoring Stack

```bash
cd "D:\POProject\Bubble Tea\monitoring"
docker-compose up -d
```

This will start:
- **Prometheus** (port 9090) - Metrics collection
- **Grafana** (port 3000) - Visualization
- **PostgreSQL Exporter** (port 9187) - Database metrics
- **AlertManager** (port 9093) - Alerting

### Step 2: Verify Services

```bash
docker-compose ps
```

All services should be "Up" (green).

### Step 3: Access Grafana

1. Open http://localhost:3000
2. Login:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted

### Step 4: Configure Prometheus Data Source

1. In Grafana: **Configuration → Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - Name: `Prometheus`
   - URL: `http://prometheus:9090`
5. Click **Save & Test**

### Step 5: Import Dashboard

1. Go to **Create → Import**
2. Upload file: `monitoring/grafana/provisioning/dashboards/bubble_tea_dashboard.json`
3. Select Prometheus data source
4. Click **Import**

### Available Metrics

- **Flask App Metrics:**
  - Request count
  - Response time
  - Error rate
  - Active users

- **PostgreSQL Metrics:**
  - Active connections
  - Transaction rate
  - Database size
  - Query performance

### Alerts

Configured in `monitoring/prometheus/alert_rules.yml`:
- High error rate (>5%)
- Database down
- Too many connections (>80)
- Flask app down

---

## 💾 Backup System

### Architecture

**Automated backups using pgAgent:**
- **Daily Logical Backup:** 2:00 AM (pg_dump)
- **Weekly Physical Backup:** Sunday 3:00 AM (pg_basebackup)

### Step 1: Verify pgAgent Service

```powershell
Get-Service | Where-Object {$_.Name -like "*agent*"}
```

Expected output:
```
Name                 DisplayName                    Status
----                 -----------                    ------
pgagent-pg17         PostgreSQL Scheduling Agent    Running
```

**If NOT running:**

```bash
cd "D:\POProject\Bubble Tea\database\backup_scripts"
install_pgagent_service.bat
```

### Step 2: Create pgAgent Jobs

1. Open **pgAdmin 4**
2. Connect to PostgreSQL server
3. Open **Query Tool** (Tools → Query Tool)
4. Load file: `database\backup_scripts\create_pgagent_jobs.sql`
5. Execute (F5)

Expected output:
```
NOTICE: Created Job: BubbleTea Daily Logical Backup (ID: 1)
NOTICE: Created Schedule: Daily at 2:00 AM (ID: 1)
NOTICE: ✅ Daily Logical Backup Job created successfully!

NOTICE: Created Job: BubbleTea Weekly Physical Backup (ID: 2)
NOTICE: Created Schedule: Weekly Sunday at 3:00 AM (ID: 2)
NOTICE: ✅ Weekly Physical Backup Job created successfully!
```

### Step 3: Verify Jobs

In pgAdmin:
1. Expand **PostgreSQL 17**
2. Right-click **pgAgent Jobs** → Refresh
3. You should see:
   - ✅ BubbleTea Daily Logical Backup
   - ✅ BubbleTea Weekly Physical Backup

### Step 4: Test Backup Manually (Optional)

**Logical Backup:**
```bash
cd "D:\POProject\Bubble Tea\database\backup_scripts"
pg_dump_backup.bat
```

**Physical Backup:**
```bash
pg_basebackup.bat
```

Backups saved to: `D:\POProject\Bubble Tea\backups\`

### Backup Retention

- **Logical:** 30 days
- **Physical:** 7 days
- Old backups deleted automatically

### Web Interface

Access: http://localhost:5000/backup (admin only)

Features:
- 📊 View backup statistics
- 📋 List all backups
- ➕ Create manual backup
- ⚠️ View restore instructions

**⚠️ Important:** Restore must be done via command line:
```bash
cd "D:\POProject\Bubble Tea\database\backup_scripts"
restore_from_dump.bat
# Select backup from list
```

---

## 🚀 Running the Application

### Step 1: Activate Virtual Environment

```bash
cd "D:\POProject\Bubble Tea"
venv\Scripts\activate
```

### Step 2: Start Flask App

```bash
python app.py
```

Expected output:
```
* Running on http://127.0.0.1:5000
* Restarting with stat
* Debugger is active!
```

### Step 3: Access Website

Open browser: http://localhost:5000

---

## 🎯 Features Overview

### Public Features
- 🏠 Home page with featured products
- 🍵 Menu with category filtering
- 🔍 Product search (by name, description, category)
- 📝 User registration and login
- 🛒 Place orders
- 👤 User profile and order history

### Admin Features
- 📊 Admin dashboard with statistics
- 📦 Product management (CRUD)
- 👥 User management
- 📋 Order management
- 📈 Analytics and reports
- 💾 **Backup management** (http://localhost:5000/backup)

### Monitoring Features
- 📊 Real-time metrics in Grafana
- 🚨 Automated alerts
- 📈 Performance tracking
- 🗄️ Database monitoring

### Backup Features
- ⏰ Automated daily/weekly backups
- 💾 Logical backups (pg_dump)
- 📀 Physical backups (pg_basebackup)
- 🔄 Point-in-time recovery
- 🌐 Web-based backup dashboard

---

## 🔧 Troubleshooting

### Database Connection Issues

**Error:** `psycopg2.OperationalError: could not connect to server`

**Solution:**
1. Check PostgreSQL is running:
   ```powershell
   Get-Service -Name postgresql*
   ```
2. Verify `.env` password matches PostgreSQL
3. Test connection:
   ```bash
   psql -U postgres -d bibabobabebe
   ```

### Docker/Monitoring Issues

**Error:** `ERROR: Cannot connect to the Docker daemon`

**Solution:**
1. Start Docker Desktop
2. Wait for Docker to fully start (whale icon in system tray)
3. Retry:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

**Error:** `Connection refused` to Prometheus

**Solution:**
1. Check containers:
   ```bash
   docker-compose ps
   ```
2. Restart if needed:
   ```bash
   docker-compose restart prometheus
   ```

### Grafana Connection Issues

**Error:** `Post "http://localhost:9090/api/v1/query": connection refused`

**Solution:**
Use Docker network name instead of localhost:
- URL: `http://prometheus:9090` (NOT `http://localhost:9090`)

### Backup Issues

**Error:** `pgAgent service not found`

**Solution:**
```bash
cd "D:\POProject\Bubble Tea\database\backup_scripts"
install_pgagent_service.bat
```

**Error:** `PGPASSWORD not set`

**Solution:**
Verify `.env` file exists and contains `DB_PASSWORD=your_password`

**Error:** `Database is busy by other users` during restore

**Solution:**
1. Close Flask application (Ctrl+C)
2. Close all pgAdmin connections
3. Run restore again:
   ```bash
   restore_from_dump.bat
   ```

### Flask Application Issues

**Error:** `ModuleNotFoundError`

**Solution:**
```bash
venv\Scripts\activate
pip install -r requirements.txt
```

**Error:** `Port 5000 is already in use`

**Solution:**
1. Find process using port 5000:
   ```powershell
   netstat -ano | findstr :5000
   ```
2. Kill process:
   ```powershell
   taskkill /F /PID <PID>
   ```

### Full-Text Search Not Working

**Solution:**
Apply full-text search configuration:
```bash
psql -U postgres -d bibabobabebe -f database\full_text_search.sql
```

---

## 📚 Additional Resources

### File Structure

```
D:\POProject\Bubble Tea\
├── app.py                          # Main Flask application
├── backup_manager.py               # Backup management blueprint
├── create_admin.py                 # Admin user creation script
├── requirements.txt                # Python dependencies
├── .env                           # Environment variables (CREATE THIS!)
│
├── database\
│   ├── schema.sql                 # Database schema
│   ├── seed_data.sql              # Sample data
│   ├── quick_setup_db.bat         # Quick DB setup script
│   └── backup_scripts\
│       ├── pg_dump_backup.bat     # Logical backup script
│       ├── pg_basebackup.bat      # Physical backup script
│       ├── restore_from_dump.bat  # Restore script
│       ├── create_pgagent_jobs.sql # pgAgent jobs setup
│       └── PGAGENT_SETUP.md       # Detailed pgAgent guide
│
├── monitoring\
│   ├── docker-compose.yml         # Monitoring stack
│   ├── prometheus\
│   │   ├── prometheus.yml         # Prometheus config
│   │   └── alert_rules.yml        # Alert rules
│   └── grafana\
│       └── provisioning\          # Grafana dashboards
│
├── templates\                     # HTML templates
├── static\                        # CSS, JS, images
└── docs\                          # Additional documentation
```

### API Endpoints

**Search API:**
- `GET /api/search/products?q=mango` - Search products
- `GET /api/search/customers?q=john` - Search customers
- `GET /api/search/orders?q=pending` - Search orders

**Metrics API:**
- `GET /metrics` - Prometheus metrics

**Backup API:**
- `GET /backup/api/list` - List all backups
- `POST /backup/api/create` - Create backup
- `GET /backup/api/stats` - Backup statistics

---

## 🎓 Development Notes

### Virtual Environment

Always activate venv before running Python scripts:
```bash
venv\Scripts\activate
```

To deactivate:
```bash
deactivate
```

### Database Migrations

After schema changes:
```bash
psql -U postgres -d bibabobabebe -f database\schema.sql
```

### Updating Prices

```bash
psql -U postgres -d bibabobabebe -f database\update_prices.sql
```

### Performance Testing

```bash
cd database\monitoring
performance_report.bat
```

### Docker Management

```bash
# View logs
docker-compose logs -f prometheus

# Restart service
docker-compose restart grafana

# Stop all
docker-compose down

# Remove volumes (full reset)
docker-compose down -v
```

---

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#-troubleshooting) section
2. Review `database\backup_scripts\PGAGENT_SETUP.md` for detailed backup setup
3. Check Docker logs: `docker-compose logs -f`
4. Verify PostgreSQL logs in pgAdmin

---

## ✅ Verification Checklist

Before running the application, ensure:

- ✅ PostgreSQL 17 installed and running
- ✅ Python 3.8+ installed
- ✅ Docker Desktop running
- ✅ `.env` file created with correct password
- ✅ Database created (`quick_setup_db.bat`)
- ✅ Admin user created (`create_admin.py`)
- ✅ Virtual environment activated
- ✅ Dependencies installed (`pip install -r requirements.txt`)
- ✅ Monitoring stack running (`docker-compose up -d`)
- ✅ pgAgent service running
- ✅ pgAgent jobs created (`create_pgagent_jobs.sql`)
- ✅ Flask app running (`python app.py`)

**All green? You're ready to go! 🚀**

---

## 🏆 Project Criteria Fulfillment

### Monitoring & Management
✅ Grafana + Prometheus integration  
✅ Real-time metrics collection  
✅ Custom dashboards  
✅ Automated alerting  
✅ PostgreSQL metrics  
✅ Application metrics  

### Backup & Recovery
✅ Automated backup system (pgAgent)  
✅ Logical backups (pg_dump)  
✅ Physical backups (pg_basebackup)  
✅ Backup retention policies  
✅ Web-based backup dashboard  
✅ Restore procedures  
✅ Point-in-time recovery (WAL archiving)  

### Database
✅ Full-text search  
✅ Optimized indexes  
✅ Transaction support  
✅ Role-based access control  

### Web Application
✅ User authentication  
✅ Admin panel  
✅ Product management  
✅ Order processing  
✅ Responsive design  

---

**Last Updated:** November 2, 2025  
**Version:** 2.0.0  
**Project:** Bubble Tea Shop Management System

