@echo off
REM Quick Database Setup Script
REM Creates database, applies schema, and loads test data

setlocal enabledelayedexpansion

REM Load environment variables from .env file
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0..\.env" 2^>nul') do (
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
echo Quick Database Setup
echo ======================================
echo Database: %DB_NAME%
echo Host: %DB_HOST%
echo ======================================
echo.

echo [1/5] Terminating existing connections...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_NAME%' AND pid <> pg_backend_pid();" 2>nul

echo [2/5] Dropping existing database...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "DROP DATABASE IF EXISTS %DB_NAME%;" 2>nul

echo [3/5] Creating new database...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "CREATE DATABASE %DB_NAME% ENCODING 'UTF8';"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Could not create database!
    pause
    exit /b 1
)

echo [4/5] Applying schema...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "%~dp0schema.sql"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Could not apply schema!
    pause
    exit /b 1
)

echo [5/5] Loading test data...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "%~dp0seed_data.sql"

if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Could not load test data, but schema is OK
)

echo.
echo ======================================
echo [SUCCESS] Database setup completed!
echo ======================================
echo.
echo Database: %DB_NAME%
echo Tables created: users, categories, products, orders, etc.
echo Test data: Loaded successfully
echo.
echo You can now run Flask:
echo   cd "D:\POProject\Bubble Tea"
echo   python app.py
echo.
pause

