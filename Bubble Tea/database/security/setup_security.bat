@echo off
REM Setup PostgreSQL Security and Roles

SET PGPASSWORD=1235
SET DB_NAME=bibabobabebe
SET DB_USER=postgres
SET DB_HOST=localhost
SET DB_PORT=5432

echo ======================================
echo PostgreSQL Security Setup
echo ======================================

echo.
echo Creating database roles...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f "create_roles.sql"

if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Roles created successfully!
) else (
    echo [ERROR] Failed to create roles!
    pause
    exit /b 1
)

echo.
echo ======================================
echo IMPORTANT: Manual Steps Required
echo ======================================
echo.
echo 1. Edit pg_hba.conf file:
echo    Location: C:\Program Files\PostgreSQL\17\data\pg_hba.conf
echo.
echo 2. Add authentication rules from:
echo    database/security/pg_hba_example.conf
echo.
echo 3. Restart PostgreSQL service:
echo    - Open Services (services.msc)
echo    - Find "postgresql-x64-17"
echo    - Right-click and select "Restart"
echo.
echo 4. Update app.py to use new role:
echo    SQLALCHEMY_DATABASE_URI = 'postgresql://bubble_tea_app:app_secure_password_2024!@localhost/bibabobabebe'
echo.
echo ======================================
echo Roles Created:
echo ======================================
echo - bubble_tea_admin (Full access)
echo - bubble_tea_app (Application CRUD)
echo - bubble_tea_readonly (Read-only)
echo - bubble_tea_backup (Backup operations)
echo ======================================
pause


