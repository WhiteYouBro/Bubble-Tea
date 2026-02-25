# 🫖 Bubble Tea Shop Management System

A comprehensive web application for managing a bubble tea shop with integrated monitoring, backup system, and full-text search capabilities.

---

## 📖 Documentation

### **[📘 COMPLETE PROJECT GUIDE](COMPLETE_PROJECT_GUIDE.md)** ← START HERE!

**Main documentation file with everything you need:**
- ⚡ Quick start guide
- 💻 System requirements
- 📥 Installation instructions
- 🗄️ Database setup
- 📊 Monitoring setup (Grafana + Prometheus)
- 💾 Backup system (pgAgent)
- 🚀 Running the application
- 🔧 Troubleshooting

---

## ⚡ Quick Start (5 minutes)

### Prerequisites
- PostgreSQL 17 with pgAgent
- Python 3.8+
- Docker Desktop

### Steps

```bash
# 1. Create .env file
echo DB_HOST=localhost > .env
echo DB_PORT=5432 >> .env
echo DB_NAME=bibabobabebe >> .env
echo DB_USER=postgres >> .env
echo DB_PASSWORD=YOUR_PASSWORD >> .env

# 2. Setup database
cd database
quick_setup_db.bat

# 3. Create admin
cd ..
python create_admin.py

# 4. Install dependencies
venv\Scripts\activate
pip install -r requirements.txt

# 5. Start monitoring
cd monitoring
docker-compose up -d

# 6. Setup backups (run in pgAdmin)
# Execute: database\backup_scripts\create_pgagent_jobs.sql

# 7. Run application
cd ..
python app.py
```

**Access:**
- 🌐 Website: http://localhost:5000
- 📊 Grafana: http://localhost:3000 (admin/admin)
- 🔍 Prometheus: http://localhost:9090
- 💾 Backups: http://localhost:5000/backup

**Admin login:**
- Username: `adminkey`
- Password: `adminpass123`

---

## 🎯 Key Features

### Core Functionality
- 🍵 Product catalog with categories
- 🔍 Full-text search
- 🛒 Order management
- 👥 User authentication & profiles
- 📊 Admin dashboard
- 📈 Analytics

### Monitoring
- 📊 Real-time metrics (Grafana)
- 🚨 Automated alerts
- 🗄️ Database monitoring
- 📈 Performance tracking

### Backup System
- ⏰ Automated daily/weekly backups
- 💾 Logical backups (pg_dump)
- 📀 Physical backups (pg_basebackup)
- 🔄 Point-in-time recovery
- 🌐 Web-based management

---

## 📁 Project Structure

```
Bubble Tea/
├── app.py                          # Main Flask application
├── backup_manager.py               # Backup management
├── create_admin.py                 # Admin setup
├── .env                           # Config (CREATE THIS!)
│
├── database/
│   ├── schema.sql                 # Database schema
│   ├── seed_data.sql              # Sample data
│   ├── quick_setup_db.bat         # Quick setup script
│   └── backup_scripts/            # Backup automation
│       ├── create_pgagent_jobs.sql
│       └── PGAGENT_SETUP.md
│
├── monitoring/
│   ├── docker-compose.yml         # Monitoring stack
│   └── prometheus/
│       ├── prometheus.yml
│       └── alert_rules.yml
│
├── templates/                     # HTML templates
├── static/                        # CSS, JS, images
└── COMPLETE_PROJECT_GUIDE.md     # Full documentation
```

---

## 🔧 Common Commands

### Database
```bash
# Quick setup
cd database && quick_setup_db.bat

# Manual backup
cd database\backup_scripts
pg_dump_backup.bat

# Restore
restore_from_dump.bat
```

### Monitoring
```bash
cd monitoring

# Start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Flask App
```bash
# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run
python app.py
```

---

## 🆘 Troubleshooting

### Database connection failed?
1. Check PostgreSQL is running: `Get-Service postgresql*`
2. Verify `.env` password
3. Test: `psql -U postgres -d bibabobabebe`

### Docker not working?
1. Start Docker Desktop
2. Wait for Docker to start completely
3. Run: `docker-compose restart`

### Backup system not working?
1. Check pgAgent service: `Get-Service | Where-Object {$_.Name -like "*agent*"}`
2. If not running: `cd database\backup_scripts && install_pgagent_service.bat`
3. Create jobs in pgAdmin: `create_pgagent_jobs.sql`

**For detailed troubleshooting, see [COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md#-troubleshooting)**

---

## 📚 Additional Documentation

- **[COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md)** - Main guide (START HERE!)
- **[database/backup_scripts/PGAGENT_SETUP.md](database/backup_scripts/PGAGENT_SETUP.md)** - pgAgent detailed setup
- **[docs/USE_CASE_DIAGRAM.md](docs/USE_CASE_DIAGRAM.md)** - Use case diagram
- **[docs/DATA_FLOW_DIAGRAM.md](docs/DATA_FLOW_DIAGRAM.md)** - Data flow diagram
- **[docs/BACKUP_TOOLS_COMPARISON.md](docs/BACKUP_TOOLS_COMPARISON.md)** - Backup tools comparison

---

## 🛠️ Technology Stack

- **Backend:** Python 3.14, Flask
- **Database:** PostgreSQL 17
- **Monitoring:** Grafana, Prometheus, AlertManager
- **Backup:** pgAgent, pg_dump, pg_basebackup
- **Containerization:** Docker, Docker Compose
- **Frontend:** HTML5, CSS3, JavaScript

---

## ✅ System Requirements

- **OS:** Windows 10/11
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 10GB free space
- **Software:**
  - PostgreSQL 17 (with pgAgent)
  - Python 3.8+
  - Docker Desktop

---

## 🎓 For Developers

### Virtual Environment
```bash
# Activate
venv\Scripts\activate

# Deactivate
deactivate
```

### Database Migrations
```bash
psql -U postgres -d bibabobabebe -f database\schema.sql
```

### Performance Testing
```bash
cd database\monitoring
performance_report.bat
```

### Docker Management
```bash
# View logs for specific service
docker-compose logs -f prometheus

# Restart service
docker-compose restart grafana

# Full reset
docker-compose down -v
```

---

## 📞 Support

1. Read [COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md)
2. Check [Troubleshooting](#-troubleshooting) section
3. Review Docker logs: `docker-compose logs -f`
4. Check PostgreSQL logs in pgAdmin

---

## 🏆 Project Status

✅ **Fully functional and tested**

- ✅ Web application
- ✅ Database with full-text search
- ✅ Monitoring (Grafana + Prometheus)
- ✅ Automated backup system (pgAgent)
- ✅ Admin panel
- ✅ User authentication
- ✅ Order management

---
**📘 [READ COMPLETE GUIDE](COMPLETE_PROJECT_GUIDE.md) for full documentation!**
