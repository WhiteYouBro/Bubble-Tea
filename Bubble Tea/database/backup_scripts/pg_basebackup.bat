@echo off
REM PostgreSQL Physical Backup Script using pg_basebackup
REM This script creates a physical backup of the entire database cluster (all databases)
REM Password is loaded from .env file

REM Load environment variables from .env file
for /f "tokens=1,2 delims==" %%a in ('type "%~dp0..\..\\.env" 2^>nul') do (
    if "%%a"=="DB_PASSWORD" set PGPASSWORD=%%b
    if "%%a"=="DB_USER" set DB_USER=%%b
    if "%%a"=="DB_HOST" set DB_HOST=%%b
    if "%%a"=="DB_PORT" set DB_PORT=%%b
)

REM Set defaults if not found in .env
if not defined PGPASSWORD set PGPASSWORD=your_password
if not defined DB_USER set DB_USER=postgres
if not defined DB_HOST set DB_HOST=localhost
if not defined DB_PORT set DB_PORT=5432

SET BACKUP_DIR=%~dp0..\..\backups\physical
SET TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ======================================
echo PostgreSQL Physical Backup (pg_basebackup)
echo ======================================
echo Host: %DB_HOST%
echo Time: %date% %time%
echo ======================================

REM Create backup directory if not exists
if not exist "%BACKUP_DIR%\%TIMESTAMP%" mkdir "%BACKUP_DIR%\%TIMESTAMP%"

REM Create physical backup with WAL files
echo Creating physical backup...
pg_basebackup -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -D "%BACKUP_DIR%\%TIMESTAMP%" -F tar -z -P -v -X fetch

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Physical backup created: %TIMESTAMP%
    echo Location: %BACKUP_DIR%\%TIMESTAMP%
    
    REM Create info file
    echo Backup Info > "%BACKUP_DIR%\%TIMESTAMP%\backup_info.txt"
    echo Date: %date% %time% >> "%BACKUP_DIR%\%TIMESTAMP%\backup_info.txt"
    echo Type: Physical (pg_basebackup) >> "%BACKUP_DIR%\%TIMESTAMP%\backup_info.txt"
    echo Format: TAR compressed >> "%BACKUP_DIR%\%TIMESTAMP%\backup_info.txt"
) else (
    echo [ERROR] Physical backup failed!
    exit /b 1
)

REM Delete backups older than 7 days (physical backups are large)
echo Cleaning old physical backups (older than 7 days)...
forfiles /p "%BACKUP_DIR%" /m *.tar.gz /d -7 /c "cmd /c del @path" 2>nul

echo ======================================
echo Physical backup completed!
echo ======================================
pause


