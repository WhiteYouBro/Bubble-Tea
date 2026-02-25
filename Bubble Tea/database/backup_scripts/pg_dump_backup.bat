@echo off
REM PostgreSQL Backup Script using pg_dump
REM This script creates a logical backup of the bubble_tea database
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
SET TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ======================================
echo PostgreSQL Logical Backup (pg_dump)
echo ======================================
echo Database: %DB_NAME%
echo Time: %date% %time%
echo ======================================

REM Create backup directory if not exists
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Create backup with pg_dump (custom format for flexibility)
echo Creating backup...
pg_dump -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -F c -b -v -f "%BACKUP_DIR%\%DB_NAME%_%TIMESTAMP%.backup"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Backup created: %DB_NAME%_%TIMESTAMP%.backup
    echo File location: %BACKUP_DIR%
    
    REM Also create SQL text dump for manual review
    echo Creating SQL text dump...
    pg_dump -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -F p -f "%BACKUP_DIR%\%DB_NAME%_%TIMESTAMP%.sql"
    
    REM Delete backups older than 30 days
    echo Cleaning old backups (older than 30 days)...
    forfiles /p "%BACKUP_DIR%" /s /m *.backup /d -30 /c "cmd /c del @path" 2>nul
    forfiles /p "%BACKUP_DIR%" /s /m *.sql /d -30 /c "cmd /c del @path" 2>nul
    
    echo ======================================
    echo Backup completed successfully!
    echo ======================================
    
    REM Send Telegram notification
    cd /d "%~dp0..\.."
    python -c "from telegram_notifier import get_notifier; notifier = get_notifier(); notifier.send_backup_success('logical', '%DB_NAME%_%TIMESTAMP%.backup', 'N/A', 0)" 2>nul
    
) else (
    echo [ERROR] Backup failed!
    
    REM Send Telegram notification about error
    cd /d "%~dp0..\.."
    python -c "from telegram_notifier import get_notifier; notifier = get_notifier(); notifier.send_backup_failed('logical', 'pg_dump failed')" 2>nul
    
    exit /b 1
)


