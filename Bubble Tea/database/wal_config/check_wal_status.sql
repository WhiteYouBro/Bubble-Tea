-- Check WAL and Archiving Status
-- Run this in psql to verify WAL configuration

\echo '======================================'
\echo 'WAL and Archiving Status'
\echo '======================================'

-- Check WAL level
SELECT name, setting, context 
FROM pg_settings 
WHERE name IN ('wal_level', 'archive_mode', 'archive_command', 'max_wal_size', 'wal_keep_size');

\echo ''
\echo '======================================'
\echo 'Current WAL Location'
\echo '======================================'

-- Current WAL insert location
SELECT pg_current_wal_lsn() AS current_wal_lsn;

\echo ''
\echo '======================================'
\echo 'WAL File Statistics'
\echo '======================================'

-- Number of WAL files
SELECT 
    count(*) AS total_wal_files,
    pg_size_pretty(sum(size)) AS total_size
FROM pg_ls_waldir();

\echo ''
\echo '======================================'
\echo 'Archive Status'
\echo '======================================'

-- Check if archiving is working
SELECT 
    archived_count,
    last_archived_wal,
    last_archived_time,
    failed_count,
    last_failed_wal,
    last_failed_time
FROM pg_stat_archiver;

\echo ''
\echo '======================================'
\echo 'Recent WAL Files'
\echo '======================================'

-- List recent WAL files
SELECT 
    name,
    pg_size_pretty(size) AS size,
    modification AS modified
FROM pg_ls_waldir()
ORDER BY modification DESC
LIMIT 10;

\echo ''
\echo '======================================'
\echo 'Checkpoint Information'
\echo '======================================'

-- Last checkpoint information
SELECT 
    checkpoint_lsn,
    redo_lsn,
    timeline_id,
    prev_timeline_id,
    checkpoint_time
FROM pg_control_checkpoint();


