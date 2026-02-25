@echo off
REM Apply PostgreSQL Configuration Changes

echo ======================================
echo PostgreSQL Configuration Update
echo ======================================

echo.
echo This script will help you apply the optimized configuration.
echo.
echo MANUAL STEPS REQUIRED:
echo ======================================
echo.
echo 1. Open PostgreSQL configuration file:
echo    C:\Program Files\PostgreSQL\17\data\postgresql.conf
echo.
echo 2. Add/modify settings from:
echo    database/configuration/postgresql_optimized.conf
echo.
echo 3. Open pg_hba.conf file:
echo    C:\Program Files\PostgreSQL\17\data\pg_hba.conf
echo.
echo 4. Add authentication rules from:
echo    database/security/pg_hba_example.conf
echo.
echo 5. Restart PostgreSQL service:
echo    sc stop postgresql-x64-17
echo    sc start postgresql-x64-17
echo.
echo    Or use Services GUI (services.msc)
echo.
echo ======================================
echo Current PostgreSQL Settings
echo ======================================

SET PGPASSWORD=1235
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432

echo.
echo Checking current configuration...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SHOW shared_buffers; SHOW work_mem; SHOW maintenance_work_mem; SHOW effective_cache_size; SHOW max_connections; SHOW wal_level; SHOW archive_mode;"

echo.
echo ======================================
echo Configuration files location:
echo ======================================
echo Optimized postgresql.conf:
echo   database/configuration/postgresql_optimized.conf
echo.
echo Security pg_hba.conf:
echo   database/security/pg_hba_example.conf
echo.
echo WAL settings:
echo   database/wal_config/postgresql_wal_settings.conf
echo ======================================

pause


