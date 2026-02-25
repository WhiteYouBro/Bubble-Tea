@echo off
REM Setup Automated Tasks for PostgreSQL Maintenance

echo ======================================
echo PostgreSQL Automation Setup
echo ======================================

echo.
echo This script will create scheduled tasks for:
echo 1. Daily backups at 2:00 AM
echo 2. Weekly VACUUM ANALYZE at 3:00 AM Sunday
echo 3. Daily monitoring reports at 6:00 AM
echo.
set /p CONFIRM="Continue? (yes/no): "

if not "%CONFIRM%"=="yes" (
    echo Setup cancelled.
    exit /b 0
)

echo.
echo ======================================
echo Creating Scheduled Tasks
echo ======================================

REM Task 1: Daily Backup
echo.
echo Creating daily backup task...
schtasks /create /tn "PostgreSQL Bubble Tea - Daily Backup" /tr "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\database\backup_scripts\pg_dump_backup.bat" /sc daily /st 02:00 /f

if %ERRORLEVEL% EQU 0 (
    echo [OK] Daily backup task created
) else (
    echo [ERROR] Failed to create daily backup task
)

REM Task 2: Weekly Maintenance
echo.
echo Creating weekly maintenance task...
schtasks /create /tn "PostgreSQL Bubble Tea - Weekly Maintenance" /tr "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\database\automation\weekly_maintenance.bat" /sc weekly /d SUN /st 03:00 /f

if %ERRORLEVEL% EQU 0 (
    echo [OK] Weekly maintenance task created
) else (
    echo [ERROR] Failed to create weekly maintenance task
)

REM Task 3: Daily Monitoring
echo.
echo Creating daily monitoring task...
schtasks /create /tn "PostgreSQL Bubble Tea - Daily Monitoring" /tr "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\database\monitoring\performance_report.bat" /sc daily /st 06:00 /f

if %ERRORLEVEL% EQU 0 (
    echo [OK] Daily monitoring task created
) else (
    echo [ERROR] Failed to create daily monitoring task
)

echo.
echo ======================================
echo Viewing Created Tasks
echo ======================================
schtasks /query /tn "PostgreSQL Bubble Tea*" /fo LIST

echo.
echo ======================================
echo Automation Setup Complete!
echo ======================================
echo.
echo Tasks created:
echo - Daily Backup: 2:00 AM every day
echo - Weekly Maintenance: 3:00 AM every Sunday
echo - Daily Monitoring: 6:00 AM every day
echo.
echo To manage tasks, use Task Scheduler (taskschd.msc)
echo To disable a task: schtasks /change /tn "TaskName" /disable
echo To enable a task: schtasks /change /tn "TaskName" /enable
echo To delete a task: schtasks /delete /tn "TaskName"
pause


