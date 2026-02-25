@echo off
REM Setup PostgreSQL Master for Streaming Replication

SET PGPASSWORD=1235
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432
SET REPLICATION_USER=bubble_tea_backup
SET REPLICATION_PASSWORD=backup_secure_password_2024!

echo ======================================
echo PostgreSQL Master Setup
echo ======================================

echo.
echo STEP 1: Create replication user (if not exists)
echo ======================================
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT 1 FROM pg_roles WHERE rolname='%REPLICATION_USER%'" | findstr /C:"1" >nul
if %ERRORLEVEL% NEQ 0 (
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "CREATE ROLE %REPLICATION_USER% WITH REPLICATION LOGIN PASSWORD '%REPLICATION_PASSWORD%';"
    echo [OK] Replication user created
) else (
    echo [OK] Replication user already exists
)

echo.
echo STEP 2: Configure postgresql.conf
echo ======================================
echo Add these settings to postgresql.conf:
echo.
echo wal_level = replica
echo max_wal_senders = 3
echo max_replication_slots = 3
echo hot_standby = on
echo.
echo Location: C:\Program Files\PostgreSQL\17\data\postgresql.conf

echo.
echo STEP 3: Configure pg_hba.conf
echo ======================================
echo Add this line to pg_hba.conf:
echo.
echo host replication %REPLICATION_USER% 127.0.0.1/32 scram-sha-256
echo.
echo Location: C:\Program Files\PostgreSQL\17\data\pg_hba.conf

echo.
echo STEP 4: Restart PostgreSQL
echo ======================================
echo Restart PostgreSQL service to apply changes
echo.
echo Run: sc stop postgresql-x64-17 ^&^& sc start postgresql-x64-17

echo.
echo ======================================
echo Master configuration complete!
echo ======================================
echo.
echo Next: Run setup_replication_standby.bat on standby server
pause


