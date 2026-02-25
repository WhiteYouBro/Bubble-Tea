# PowerShell script to start monitoring services with proper environment setup

# Set the PGPASSWORD environment variable for the PostgreSQL exporter
$env:PGPASSWORD = "1235"

# Change to the monitoring directory
Set-Location -Path "C:\Users\VICTUS\Downloads\Alisher Downloads\Bubble Tea\monitoring"

# Start the Docker Compose services
docker-compose up -d

Write-Host "Monitoring services started!"
Write-Host "Access the services at:"
Write-Host " - Grafana: http://localhost:3000 (admin/admin)"
Write-Host " - Prometheus: http://localhost:9090"
Write-Host " - PostgreSQL Exporter: http://localhost:9187"