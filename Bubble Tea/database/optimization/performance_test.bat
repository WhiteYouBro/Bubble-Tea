@echo off
REM PostgreSQL Performance Testing with pgbench

SET PGPASSWORD=1235
SET DB_NAME=bibabobabebe
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432
SET REPORT_DIR=C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\reports
SET TIMESTAMP=%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

echo ======================================
echo PostgreSQL Performance Testing
echo ======================================
echo Database: %DB_NAME%
echo Time: %date% %time%
echo ======================================

REM Create reports directory
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

echo.
echo TEST 1: Query Performance Analysis
echo ======================================
echo Running EXPLAIN ANALYZE on key queries...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "analyze_queries.sql" > "%REPORT_DIR%\query_analysis_%TIMESTAMP%.txt"

if %ERRORLEVEL% EQU 0 (
    echo [OK] Query analysis complete
) else (
    echo [ERROR] Query analysis failed!
)

echo.
echo TEST 2: Creating Optimized Indexes
echo ======================================
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "create_optimized_indexes.sql"

echo.
echo TEST 3: pgbench Benchmark
echo ======================================
echo.
echo Running pgbench benchmark (read-only test)...
echo Clients: 10, Threads: 2, Transactions: 1000
echo.

pgbench -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c 10 -j 2 -t 1000 -S > "%REPORT_DIR%\pgbench_readonly_%TIMESTAMP%.txt"

echo.
echo [OK] Read-only benchmark complete

echo.
echo Running pgbench benchmark (read-write test)...
pgbench -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c 10 -j 2 -t 500 > "%REPORT_DIR%\pgbench_readwrite_%TIMESTAMP%.txt"

echo.
echo [OK] Read-write benchmark complete

echo.
echo TEST 4: Custom Workload Simulation
echo ======================================
echo Simulating typical application queries...

REM Run 100 iterations of common queries
FOR /L %%i IN (1,1,100) DO (
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT * FROM orders ORDER BY order_date DESC LIMIT 10;" >nul
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT * FROM products WHERE is_available = true;" >nul
    psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT COUNT(*) FROM order_items;" >nul
)

echo [OK] Workload simulation complete

echo.
echo ======================================
echo Performance Testing Complete!
echo ======================================
echo.
echo Reports saved to: %REPORT_DIR%
echo - query_analysis_%TIMESTAMP%.txt
echo - pgbench_readonly_%TIMESTAMP%.txt
echo - pgbench_readwrite_%TIMESTAMP%.txt
echo.
echo Opening query analysis report...
start notepad "%REPORT_DIR%\query_analysis_%TIMESTAMP%.txt"

pause


