@echo off
REM ================================================================
REM pgAgent Service Installation Script
REM Automatically detects PostgreSQL location and installs pgAgent
REM ================================================================

setlocal enabledelayedexpansion

echo ========================================
echo pgAgent Service Installation
echo ========================================
echo.

REM Load DB password from .env
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0..\..\\.env" 2^>nul') do (
    if "%%a"=="DB_PASSWORD" set DB_PASSWORD=%%b
)

if not defined DB_PASSWORD set DB_PASSWORD=admin1235

echo PostgreSQL Location: D:\Programs\PostgreSQL\bin
echo Database: postgres
echo User: postgres
echo.

REM Install pgAgent service
echo Installing pgAgent service...
"D:\Programs\PostgreSQL\bin\pgagent.exe" INSTALL pgAgent ^
    -u postgres ^
    -p %DB_PASSWORD% ^
    hostaddr=127.0.0.1 ^
    port=5432 ^
    dbname=postgres

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] pgAgent service installed!
    echo.
    
    echo Starting pgAgent service...
    sc start pgAgent
    
    if %ERRORLEVEL% EQU 0 (
        echo [SUCCESS] pgAgent service started!
    ) else (
        echo [WARNING] Could not start service. Try: sc start pgAgent
    )
) else (
    echo [ERROR] Service installation failed!
    echo.
    echo Possible reasons:
    echo - Service already exists (run: sc delete pgAgent)
    echo - Incorrect password
    echo - PostgreSQL not running
    pause
    exit /b 1
)

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Service status:
sc query pgAgent
echo.
echo Next steps:
echo 1. Run create_pgagent_jobs.sql in pgAdmin
echo 2. Check jobs in: pgAgent Jobs
echo.
pause

