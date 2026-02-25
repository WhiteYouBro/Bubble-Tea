@echo off
REM Setup and start monitoring for Bubble Tea application

echo ======================================
echo Bubble Tea Monitoring Setup
echo ======================================

echo.
echo Creating necessary directories...
mkdir "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\monitoring\prometheus\data" 2>nul
mkdir "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\monitoring\grafana\data" 2>nul

echo.
echo Checking if Docker is installed...
docker --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Docker is installed
) else (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo.
echo Starting monitoring services...
cd /d "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\monitoring"
docker-compose up -d

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Monitoring services started!
    echo.
    echo Access the services at:
    echo  - Grafana: http://localhost:3000 (admin/admin)
    echo  - Prometheus: http://localhost:9090
    echo  - PostgreSQL Exporter: http://localhost:9187
    echo.
    echo To stop the services, run: docker-compose down
) else (
    echo.
    echo [ERROR] Failed to start monitoring services
    pause
    exit /b 1
)

echo.
echo Setup complete!
pause