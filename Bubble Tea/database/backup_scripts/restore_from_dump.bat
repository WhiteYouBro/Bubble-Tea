@echo off
setlocal enabledelayedexpansion
REM PostgreSQL Restore Script from pg_dump backup
REM This script restores the database from a logical backup
REM Password is loaded from .env file

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

SET BACKUP_DIR=%~dp0..\..\backups\logical

echo ======================================
echo PostgreSQL Database Restore
echo ======================================

REM Check if backup file is passed as argument or environment variable
if not "%~1"=="" (
    REM Argument passed from web interface
    set RESTORE_FILE=%~1
    echo [WEB] Using backup from argument: %RESTORE_FILE%
) else if not "%BACKUP_FILE%"=="" (
    REM Environment variable from web interface
    set RESTORE_FILE=%BACKUP_FILE%
    echo [WEB] Using backup from environment: %RESTORE_FILE%
) else (
    REM Interactive mode
    echo Available backups:
    echo ======================================
    dir /b "%BACKUP_DIR%\*.backup"
    echo ======================================
    
    set /p BACKUP_INPUT="Enter backup filename (or 'latest' for most recent): "
    
    if "%BACKUP_INPUT%"=="latest" (
        REM Get the latest backup file
        for /f "delims=" %%i in ('dir /b /o-d "%BACKUP_DIR%\*.backup" 2^>nul') do (
            set RESTORE_FILE=%BACKUP_DIR%\%%i
            goto :found
        )
    ) else (
        set RESTORE_FILE=%BACKUP_DIR%\%BACKUP_INPUT%
    )
)

:found
if not exist "%RESTORE_FILE%" (
    echo [ERROR] Backup file not found: %RESTORE_FILE%
    echo Tried path: %RESTORE_FILE%
    pause
    exit /b 1
)

echo Selected backup: %RESTORE_FILE%
echo.

REM Check for auto-confirmation (web interface)
if not "%~2"=="auto" (
    echo WARNING: This will drop and recreate the database!
    set /p CONFIRM="Are you sure? (yes/no): "
    if not "!CONFIRM!"=="yes" (
        echo Restore cancelled.
        pause
        exit /b 0
    )
) else (
    echo [AUTO] Automatic confirmation from web interface
)

echo.
echo Terminating all connections to database...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '%DB_NAME%' AND pid <> pg_backend_pid();"

echo Dropping existing database...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "DROP DATABASE IF EXISTS %DB_NAME%;"

if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Could not drop database. Trying to continue...
)

echo Creating new database...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d postgres -c "CREATE DATABASE %DB_NAME% ENCODING 'UTF8';"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Could not create database!
    pause
    exit /b 1
)

echo Restoring from backup...
pg_restore -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -v "%RESTORE_FILE%"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Database restored successfully!
    echo Database: %DB_NAME%
    echo From: %RESTORE_FILE%
) else (
    echo [ERROR] Restore failed! Error code: %ERRORLEVEL%
    exit /b 1
)

echo ======================================
echo Restore completed!
echo ======================================
pause


