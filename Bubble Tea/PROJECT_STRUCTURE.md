# 📁 Project Structure Overview

## 🎯 Main Documentation

### **Primary Guide (START HERE!)**
📘 **[COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md)** - Complete setup and usage guide
- Quick start
- Installation
- Database setup
- Monitoring setup (Grafana + Prometheus)
- Backup system (pgAgent)
- Troubleshooting

### **Quick Reference**
📖 **[README.md](README.md)** - Project overview and quick commands

---

## 📂 Project Files

### Core Application
```
├── app.py                          # Main Flask application
├── backup_manager.py               # Backup management blueprint
├── create_admin.py                 # Admin user creation
├── requirements.txt                # Python dependencies
└── .env                           # Environment config (CREATE THIS!)
```

### Database
```
database/
├── schema.sql                     # Database schema
├── seed_data.sql                  # Sample data
├── full_text_search.sql           # Full-text search setup
├── update_prices.sql              # Price update script
├── quick_setup_db.bat             # Quick database setup
│
├── backup_scripts/
│   ├── pg_dump_backup.bat         # Logical backup
│   ├── pg_basebackup.bat          # Physical backup
│   ├── restore_from_dump.bat      # Restore script
│   ├── close_connections.bat      # Close all DB connections
│   ├── install_pgagent_service.bat # Install pgAgent
│   ├── create_pgagent_jobs.sql    # pgAgent jobs setup
│   └── PGAGENT_SETUP.md           # Detailed pgAgent guide
│
├── configuration/
│   ├── postgresql_optimized.conf  # PostgreSQL optimization
│   └── apply_config.bat           # Apply config script
│
├── monitoring/
│   ├── monitoring_queries.sql     # Monitoring queries
│   └── performance_report.bat     # Generate performance report
│
├── optimization/
│   ├── create_optimized_indexes.sql
│   ├── analyze_queries.sql
│   └── performance_test.bat
│
├── security/
│   ├── create_roles.sql           # User roles
│   ├── setup_security.bat         # Security setup
│   └── pg_hba_UPDATED.conf        # PostgreSQL auth config
│
└── wal_config/
    ├── setup_wal_archive.bat      # WAL archiving setup
    ├── check_wal_status.sql       # Check WAL status
    └── postgresql_wal_settings.conf
```

### Monitoring Stack
```
monitoring/
├── docker-compose.yml             # Monitoring services
│
├── prometheus/
│   ├── prometheus.yml             # Prometheus config
│   └── alert_rules.yml            # Alert rules
│
├── grafana/
│   └── provisioning/
│       ├── dashboards/
│       │   ├── bubble_tea_dashboard.json
│       │   └── dashboard.yml
│       └── datasources/
│           └── prometheus.yml
│
├── alertmanager/
│   └── alertmanager.yml           # AlertManager config
│
├── setup_monitoring.bat           # Setup script
└── start_monitoring.ps1           # Start script
```

### Web Application
```
templates/                         # HTML templates
├── base.html                      # Base template
├── index.html                     # Home page
├── login.html                     # Login page
├── register.html                  # Registration
├── menu.html                      # Product menu
├── search.html                    # Search page
│
├── admin/
│   ├── dashboard.html             # Admin dashboard
│   ├── products.html              # Product management
│   ├── product_form.html          # Product form
│   ├── users_list.html            # User management
│   └── user_profile.html          # User profile
│
├── backup/
│   ├── index.html                 # Backup dashboard
│   ├── create.html                # Create backup
│   ├── list.html                  # List backups
│   └── restore.html               # Restore instructions
│
├── orders_list.html               # Orders
├── order_detail.html              # Order details
├── new_order.html                 # New order
├── customers_list.html            # Customers
├── employees_list.html            # Employees
├── inventory.html                 # Inventory
├── analytics.html                 # Analytics
├── profile.html                   # User profile
├── profile_orders.html            # User orders
├── profile_settings.html          # Profile settings
├── 404.html                       # Error page
└── 500.html                       # Error page

static/
├── css/
│   └── style.css                  # Main stylesheet
│
├── js/
│   └── main.js                    # Main JavaScript
│
└── images/
    ├── logo.png
    └── products/
        ├── mango-fresh.jpg
        └── README.md
```

### Documentation
```
docs/
├── USE_CASE_DIAGRAM.md            # Use case diagram
├── DATA_FLOW_DIAGRAM.md           # Data flow diagram
└── BACKUP_TOOLS_COMPARISON.md     # Backup tools comparison
```

### Backups
```
backups/
├── logical/                       # Logical backups (pg_dump)
│   └── bibabobabebe_YYYYMMDD_HHMMSS.backup
│
├── physical/                      # Physical backups (pg_basebackup)
│   └── YYYYMMDD_HHMMSS/
│       ├── backup_info.txt
│       ├── backup_manifest
│       └── base.tar.gz
│
└── wal_archive/                   # WAL archives
```

### Reports
```
reports/
└── performance_report_YYYYMMDD_HHMMSS.txt
```

---

## 🗑️ Cleaned Up Files

The following duplicate and outdated files were removed:

### Removed Documentation
- ❌ `BACKUP_RECOVERY_STRATEGY.md` (merged into COMPLETE_PROJECT_GUIDE.md)
- ❌ `SETUP_GUIDE.md` (replaced by COMPLETE_PROJECT_GUIDE.md)
- ❌ `БЫСТРЫЙ_СТАРТ.md` (Russian duplicate)
- ❌ `КРИТЕРИИ_РЕЗЕРВНОЕ_КОПИРОВАНИЕ.md` (criteria check file)
- ❌ `НАСТРОЙКА_BACKUP_СИСТЕМЫ.md` (merged into COMPLETE_PROJECT_GUIDE.md)
- ❌ `ПАМЯТКА_БЫСТРЫЙ_СТАРТ.md` (Russian memo)
- ❌ `ПРОВЕРКА_КРИТЕРИЕВ.md` (criteria check file)
- ❌ `monitoring/README.md` (merged into COMPLETE_PROJECT_GUIDE.md)
- ❌ `monitoring/TROUBLESHOOTING.md` (merged into COMPLETE_PROJECT_GUIDE.md)

### Removed Backup Scripts
- ❌ `database/backup_scripts/SETUP_SCHEDULED_BACKUPS.md` (old Task Scheduler method)
- ❌ `database/backup_scripts/SIMPLE_SCHEDULED_BACKUPS.md` (old method)

### Removed Code Files
- ❌ `app — копия.py` (duplicate file)

**Total removed: 12 files**

---

## 📊 File Statistics

### Documentation
- ✅ 1 main guide (COMPLETE_PROJECT_GUIDE.md)
- ✅ 1 quick reference (README.md)
- ✅ 1 structure overview (PROJECT_STRUCTURE.md - this file)
- ✅ 4 technical docs (in docs/ folder)

### Python Files
- ✅ 2 main application files (app.py, backup_manager.py)
- ✅ 1 setup script (create_admin.py)

### Database Scripts
- ✅ 4 SQL schema files
- ✅ 6 backup scripts (.bat)
- ✅ 2 SQL setup files for pgAgent
- ✅ Multiple optimization and monitoring SQL files

### Configuration
- ✅ 1 Docker Compose file
- ✅ 3 Prometheus/Grafana configs
- ✅ 3 PostgreSQL config files

### Templates
- ✅ 27 HTML templates

---

## 🎯 Quick Navigation

### For Setup
1. Read: [COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md)
2. Create: `.env` file
3. Run: `database/quick_setup_db.bat`
4. Run: `create_admin.py`
5. Start: `monitoring/docker-compose up -d`
6. Execute: `database/backup_scripts/create_pgagent_jobs.sql` in pgAdmin

### For Daily Use
- Run app: `python app.py`
- Check monitoring: http://localhost:3000
- Manage backups: http://localhost:5000/backup
- Admin panel: http://localhost:5000/admin

### For Maintenance
- Create manual backup: `database/backup_scripts/pg_dump_backup.bat`
- Check pgAgent jobs: pgAdmin → pgAgent Jobs
- View metrics: Grafana dashboards
- Performance report: `database/monitoring/performance_report.bat`

---

## ✨ Clean & Organized!

The project is now clean with:
- ✅ No duplicate files
- ✅ One main guide
- ✅ Clear structure
- ✅ Organized documentation
- ✅ Easy to navigate

**For complete instructions, see [COMPLETE_PROJECT_GUIDE.md](COMPLETE_PROJECT_GUIDE.md)!**

