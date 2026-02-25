@echo off
REM Close all connections to database
REM This script terminates all active connections to allow safe backup/restore operations

REM Load environment variables from .env file
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0..\..\\.env" 2^>nul') do (
    if "%%a"=="DB_PASSWORD" set PGPASSWORD=%%b
    if "%%a"=="DB_USER" set DB_USER=%%b
    if "%%a"=="DB_NAME" set DB_NAME=%%b
    if "%%a"=="DB_HOST" set DB_HOST=%%b
    if "%%a"=="DB_PORT" set DB_PORT=%%b
)

REM Set defaults if not found in .env
if not defined PGPASSWORD set PGPASSWORD=your_password
if not defined DB_USER set DB_USER=postgres
if not defined DB_NAME set DB_NAME=bibabobabebe
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432

echo ======================================
echo Closing Database Connections
echo ======================================
echo Database: %DB_NAME%
echo Host: %DB_HOST%
echo ======================================

REM Show current connections
echo Current connections:
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT pid, usename, application_name, client_addr FROM pg_stat_activity WHERE datname = '%DB_NAME%';"

echo.
echo Terminating all connections...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_NAME%' AND pid <> pg_backend_pid();"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] All connections closed!
) else (
    echo [ERROR] Could not close connections!
    exit /b 1
)

echo ======================================
echo Done!
echo ======================================
pause

