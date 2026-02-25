@echo off
REM Setup PostgreSQL Standby for Streaming Replication

SET MASTER_HOST=localhost
SET MASTER_PORT=5432
SET REPLICATION_USER=bubble_tea_backup
SET PGPASSWORD=backup_secure_password_2024!
SET STANDBY_DATA_DIR=C:\PostgreSQL\standby_data

echo ======================================
echo PostgreSQL Standby Setup
echo ======================================
echo.
echo WARNING: This will create a new standby server
echo Master: %MASTER_HOST%:%MASTER_PORT%
echo Standby directory: %STANDBY_DATA_DIR%
echo.
set /p CONFIRM="Continue? (yes/no): "

if not "%CONFIRM%"=="yes" (
    echo Setup cancelled.
    exit /b 0
)

echo.
echo STEP 1: Create standby data directory
echo ======================================
if exist "%STANDBY_DATA_DIR%" (
    echo Removing existing directory...
    rmdir /s /q "%STANDBY_DATA_DIR%"
)
mkdir "%STANDBY_DATA_DIR%"

echo.
echo STEP 2: Create base backup from master
echo ======================================
pg_basebackup -h %MASTER_HOST% -p %MASTER_PORT% -U %REPLICATION_USER% -D "%STANDBY_DATA_DIR%" -P -v -R -X stream -C -S standby_slot

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Base backup failed!
    pause
    exit /b 1
)

echo.
echo STEP 3: Configure standby
echo ======================================
echo Creating standby.signal file...
type nul > "%STANDBY_DATA_DIR%\standby.signal"

echo.
echo Standby configuration in postgresql.auto.conf:
type "%STANDBY_DATA_DIR%\postgresql.auto.conf"

echo.
echo STEP 4: Start standby server
echo ======================================
echo To start the standby server, run:
echo pg_ctl -D "%STANDBY_DATA_DIR%" start
echo.
echo Or install as Windows service:
echo pg_ctl register -N postgresql-standby -D "%STANDBY_DATA_DIR%"
echo sc start postgresql-standby

echo.
echo ======================================
echo Standby setup complete!
echo ======================================
echo.
echo To verify replication:
echo 1. On master: psql -c "SELECT * FROM pg_stat_replication;"
echo 2. On standby: psql -p 5433 -c "SELECT pg_is_in_recovery();"
pause


