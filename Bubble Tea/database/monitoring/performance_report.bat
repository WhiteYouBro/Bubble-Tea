@echo off
REM Generate PostgreSQL Performance Report

SET PGPASSWORD=1235
SET DB_NAME=bibabobabebe
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432
SET REPORT_DIR=C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\reports
SET TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ======================================
echo PostgreSQL Performance Report
echo ======================================
echo Database: %DB_NAME%
echo Time: %date% %time%
echo ======================================

REM Create reports directory
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

echo.
echo Generating performance report...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "monitoring_queries.sql" > "%REPORT_DIR%\performance_report_%TIMESTAMP%.txt"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Report generated!
    echo Location: %REPORT_DIR%\performance_report_%TIMESTAMP%.txt
) else (
    echo [ERROR] Failed to generate report!
    pause
    exit /b 1
)

echo.
echo Opening report...
start notepad "%REPORT_DIR%\performance_report_%TIMESTAMP%.txt"

echo ======================================
echo Report Complete!
echo ======================================
pause


