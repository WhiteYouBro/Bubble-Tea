@echo off
REM Setup WAL Archiving for PostgreSQL

SET WAL_ARCHIVE_DIR=C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\backups\wal_archive

echo ======================================
echo WAL Archiving Setup
echo ======================================

REM Create WAL archive directory
if not exist "%WAL_ARCHIVE_DIR%" (
    mkdir "%WAL_ARCHIVE_DIR%"
    echo [OK] Created WAL archive directory: %WAL_ARCHIVE_DIR%
) else (
    echo [OK] WAL archive directory already exists
)

echo.
echo ======================================
echo MANUAL STEPS REQUIRED:
echo ======================================
echo.
echo 1. Open PostgreSQL configuration file:
echo    C:\Program Files\PostgreSQL\17\data\postgresql.conf
echo.
echo 2. Add or modify these settings:
echo    wal_level = replica
echo    archive_mode = on
echo    archive_command = 'copy "%%p" "%WAL_ARCHIVE_DIR%\%%f"'
echo.
echo 3. Restart PostgreSQL service:
echo    - Open Services (services.msc)
echo    - Find "postgresql-x64-17"
echo    - Right-click and select "Restart"
echo.
echo 4. Or restart using command:
echo    pg_ctl restart -D "C:\Program Files\PostgreSQL\17\data"
echo.
echo ======================================
echo Configuration file location:
echo database/wal_config/postgresql_wal_settings.conf
echo ======================================
pause


