-- PostgreSQL Monitoring and Diagnostic Queries
-- Use these queries to monitor database health and performance

\echo '======================================'
\echo 'PostgreSQL Monitoring Dashboard'
\echo '======================================'

-- ======================================
-- 1. Current Database Activity
-- ======================================
\echo ''
\echo '1. Active Connections and Queries'
\echo '--------------------------------------'

SELECT 
    pid,
    usename AS username,
    application_name,
    client_addr,
    state,
    query_start,
    state_change,
    wait_event_type,
    wait_event,
    LEFT(query, 50) AS current_query
FROM pg_stat_activity
WHERE datname = 'bibabobabebe'
    AND state != 'idle'
ORDER BY query_start DESC;

-- ======================================
-- 2. Database Statistics
-- ======================================
\echo ''
\echo '2. Database Size and Statistics'
\echo '--------------------------------------'

SELECT 
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS size,
    numbackends AS connections,
    xact_commit AS transactions_committed,
    xact_rollback AS transactions_rolled_back,
    blks_read AS blocks_read,
    blks_hit AS blocks_hit,
    ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_ratio,
    tup_returned AS rows_returned,
    tup_fetched AS rows_fetched,
    tup_inserted AS rows_inserted,
    tup_updated AS rows_updated,
    tup_deleted AS rows_deleted,
    conflicts,
    temp_files,
    pg_size_pretty(temp_bytes) AS temp_bytes,
    deadlocks,
    stats_reset
FROM pg_stat_database
WHERE datname = 'bibabobabebe';

-- ======================================
-- 3. Table Statistics
-- ======================================
\echo ''
\echo '3. Table Size and Usage'
\echo '--------------------------------------'

SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_row_percent,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ======================================
-- 4. Index Usage
-- ======================================
\echo ''
\echo '4. Index Usage Statistics'
\echo '--------------------------------------'

SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 50 THEN 'RARELY USED'
        ELSE 'FREQUENTLY USED'
    END AS usage_status
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;

-- ======================================
-- 5. Slow Queries (requires pg_stat_statements)
-- ======================================
\echo ''
\echo '5. Slowest Queries (Top 10)'
\echo '--------------------------------------'

SELECT 
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS percent_total,
    LEFT(query, 80) AS query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'bibabobabebe')
ORDER BY total_exec_time DESC
LIMIT 10;

-- ======================================
-- 6. Lock Information
-- ======================================
\echo ''
\echo '6. Current Locks'
\echo '--------------------------------------'

SELECT 
    pl.pid,
    pa.usename,
    pa.application_name,
    pl.locktype,
    pl.relation::regclass AS relation,
    pl.mode,
    pl.granted,
    pa.query_start,
    LEFT(pa.query, 50) AS query
FROM pg_locks pl
LEFT JOIN pg_stat_activity pa ON pl.pid = pa.pid
WHERE pl.database = (SELECT oid FROM pg_database WHERE datname = 'bibabobabebe')
ORDER BY pl.granted, pa.query_start;

-- ======================================
-- 7. Bloat Analysis
-- ======================================
\echo ''
\echo '7. Table Bloat Analysis'
\echo '--------------------------------------'

SELECT 
    schemaname,
    tablename,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup, 0), 2) AS dead_tuple_percent,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    CASE 
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'VACUUM RECOMMENDED'
        WHEN n_dead_tup > n_live_tup * 0.1 THEN 'MONITOR'
        ELSE 'OK'
    END AS status
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;

-- ======================================
-- 8. Connection Statistics
-- ======================================
\echo ''
\echo '8. Connection Statistics'
\echo '--------------------------------------'

SELECT 
    datname AS database,
    usename AS username,
    application_name,
    COUNT(*) AS connections,
    MAX(backend_start) AS last_connection
FROM pg_stat_activity
GROUP BY datname, usename, application_name
ORDER BY connections DESC;

-- ======================================
-- 9. Checkpoint Activity
-- ======================================
\echo ''
\echo '9. Checkpoint Statistics'
\echo '--------------------------------------'

SELECT 
    checkpoints_timed,
    checkpoints_req AS checkpoints_requested,
    checkpoint_write_time,
    checkpoint_sync_time,
    buffers_checkpoint,
    buffers_clean,
    maxwritten_clean,
    buffers_backend,
    buffers_backend_fsync,
    buffers_alloc,
    stats_reset
FROM pg_stat_bgwriter;

-- ======================================
-- 10. Replication Status (if configured)
-- ======================================
\echo ''
\echo '10. Replication Status'
\echo '--------------------------------------'

SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    sync_state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS send_lag,
    pg_wal_lsn_diff(sent_lsn, write_lsn) AS write_lag,
    pg_wal_lsn_diff(write_lsn, flush_lsn) AS flush_lag,
    pg_wal_lsn_diff(flush_lsn, replay_lsn) AS replay_lag
FROM pg_stat_replication;

\echo ''
\echo '======================================'
\echo 'Monitoring Complete'
\echo '======================================'


