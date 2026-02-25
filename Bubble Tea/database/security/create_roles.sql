-- PostgreSQL Roles and Security Configuration
-- Demonstrates role-based access control and security best practices

\echo '======================================'
\echo 'Creating PostgreSQL Roles'
\echo '======================================'

-- Drop roles if they exist
DROP ROLE IF EXISTS bubble_tea_admin;
DROP ROLE IF EXISTS bubble_tea_app;
DROP ROLE IF EXISTS bubble_tea_readonly;
DROP ROLE IF EXISTS bubble_tea_backup;

-- ======================================
-- Role 1: Admin (Full access)
-- ======================================
CREATE ROLE bubble_tea_admin WITH
    LOGIN
    SUPERUSER
    CREATEDB
    CREATEROLE
    REPLICATION
    PASSWORD 'admin_secure_password_2024!';

COMMENT ON ROLE bubble_tea_admin IS 'Administrator role with full database access';

-- ======================================
-- Role 2: Application User (Normal operations)
-- ======================================
CREATE ROLE bubble_tea_app WITH
    LOGIN
    PASSWORD 'app_secure_password_2024!';

-- Grant connection to database
GRANT CONNECT ON DATABASE bibabobabebe TO bubble_tea_app;

-- Grant usage on schemas
GRANT USAGE ON SCHEMA public TO bubble_tea_app;

-- Grant table permissions (CRUD operations)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO bubble_tea_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO bubble_tea_app;

-- Future tables will also get these permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO bubble_tea_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT USAGE, SELECT ON SEQUENCES TO bubble_tea_app;

COMMENT ON ROLE bubble_tea_app IS 'Application role for Flask web app with CRUD permissions';

-- ======================================
-- Role 3: Read-Only User (Analytics, Reports)
-- ======================================
CREATE ROLE bubble_tea_readonly WITH
    LOGIN
    PASSWORD 'readonly_secure_password_2024!';

-- Grant connection
GRANT CONNECT ON DATABASE bibabobabebe TO bubble_tea_readonly;
GRANT USAGE ON SCHEMA public TO bubble_tea_readonly;

-- Only SELECT permission
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bubble_tea_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO bubble_tea_readonly;

-- Future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO bubble_tea_readonly;

-- Deny write operations explicitly
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM bubble_tea_readonly;

COMMENT ON ROLE bubble_tea_readonly IS 'Read-only role for analytics and reporting';

-- ======================================
-- Role 4: Backup User (Backup operations)
-- ======================================
CREATE ROLE bubble_tea_backup WITH
    LOGIN
    REPLICATION
    PASSWORD 'backup_secure_password_2024!';

GRANT CONNECT ON DATABASE bibabobabebe TO bubble_tea_backup;
GRANT USAGE ON SCHEMA public TO bubble_tea_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bubble_tea_backup;

COMMENT ON ROLE bubble_tea_backup IS 'Backup role for pg_dump and replication';

-- ======================================
-- Security Settings
-- ======================================

-- Revoke public access to new objects
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE bibabobabebe FROM PUBLIC;

-- Enable row-level security on sensitive tables (example)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data (example)
CREATE POLICY user_isolation_policy ON users
    FOR SELECT
    USING (user_id = current_setting('app.current_user_id')::integer);

-- Allow app role to see all users
CREATE POLICY admin_all_users ON users
    FOR ALL
    TO bubble_tea_app
    USING (true);

\echo ''
\echo '======================================'
\echo 'Roles Created Successfully!'
\echo '======================================'
\echo 'bubble_tea_admin - Full admin access'
\echo 'bubble_tea_app - Application CRUD access'
\echo 'bubble_tea_readonly - Read-only access'
\echo 'bubble_tea_backup - Backup operations'
\echo '======================================'

-- Show created roles
\du


