@echo off
REM Weekly PostgreSQL Maintenance Tasks

SET PGPASSWORD=1235
SET DB_NAME=bibabobabebe
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432
SET LOG_DIR=C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\logs
SET TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ======================================
echo PostgreSQL Weekly Maintenance
echo ======================================
echo Database: %DB_NAME%
echo Time: %date% %time%
echo ======================================

REM Create logs directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo.
echo TASK 1: VACUUM ANALYZE
echo ======================================
echo Running VACUUM ANALYZE on all tables...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "VACUUM ANALYZE VERBOSE;" > "%LOG_DIR%\vacuum_%TIMESTAMP%.log" 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [OK] VACUUM ANALYZE completed
) else (
    echo [ERROR] VACUUM ANALYZE failed!
)

echo.
echo TASK 2: REINDEX
echo ======================================
echo Rebuilding indexes...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "REINDEX DATABASE %DB_NAME%;" >> "%LOG_DIR%\vacuum_%TIMESTAMP%.log" 2>&1

if %ERRORLEVEL% EQU 0 (
    echo [OK] REINDEX completed
) else (
    echo [ERROR] REINDEX failed!
)

echo.
echo TASK 3: Update Statistics
echo ======================================
echo Updating table statistics...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "ANALYZE;" >> "%LOG_DIR%\vacuum_%TIMESTAMP%.log" 2>&1

echo [OK] Statistics updated

echo.
echo TASK 4: Check Table Bloat
echo ======================================
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT schemaname, tablename, n_dead_tup, n_live_tup FROM pg_stat_user_tables WHERE n_dead_tup > 1000 ORDER BY n_dead_tup DESC;" >> "%LOG_DIR%\vacuum_%TIMESTAMP%.log" 2>&1

echo.
echo TASK 5: Clean Old Logs
echo ======================================
echo Removing logs older than 90 days...
forfiles /p "%LOG_DIR%" /s /m *.log /d -90 /c "cmd /c del @path" 2>nul

echo.
echo ======================================
echo Weekly Maintenance Complete!
echo ======================================
echo Log file: %LOG_DIR%\vacuum_%TIMESTAMP%.log


