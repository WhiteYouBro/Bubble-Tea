@echo off
REM Stop monitoring services for Bubble Tea application

echo ======================================
echo Stopping Bubble Tea Monitoring Services
echo ======================================

echo.
echo Stopping monitoring services...
cd /d "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\monitoring"
docker-compose down

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Monitoring services stopped!
) else (
    echo.
    echo [WARNING] Some services may not have been stopped properly
)

echo.
echo To remove all data volumes, run: docker-compose down -v
pause