-- Check Replication Status
-- Run this on the MASTER server

\echo '======================================'
\echo 'PostgreSQL Replication Status'
\echo '======================================'

-- Check if this is master or standby
\echo ''
\echo 'Server Role:'
\echo '--------------------------------------'
SELECT 
    CASE pg_is_in_recovery()
        WHEN true THEN 'STANDBY (Read-only replica)'
        ELSE 'MASTER (Primary server)'
    END AS server_role;

-- Replication slots
\echo ''
\echo 'Replication Slots:'
\echo '--------------------------------------'
SELECT 
    slot_name,
    slot_type,
    database,
    active,
    restart_lsn,
    confirmed_flush_lsn
FROM pg_replication_slots;

-- Active replication connections
\echo ''
\echo 'Active Replication Connections:'
\echo '--------------------------------------'
SELECT 
    pid,
    usename AS user,
    application_name,
    client_addr AS client,
    client_hostname,
    state,
    sync_state,
    pg_current_wal_lsn() AS current_lsn,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replication_lag,
    sync_priority,
    reply_time
FROM pg_stat_replication;

-- WAL sender processes
\echo ''
\echo 'WAL Sender Statistics:'
\echo '--------------------------------------'
SELECT 
    COUNT(*) AS active_senders,
    MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS max_lag_bytes
FROM pg_stat_replication;

-- Check standby status (if this is a standby)
\echo ''
\echo 'Standby Status (if applicable):'
\echo '--------------------------------------'
SELECT 
    pg_is_in_recovery() AS is_standby,
    pg_last_wal_receive_lsn() AS last_received,
    pg_last_wal_replay_lsn() AS last_replayed,
    pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) AS replay_lag;

\echo ''
\echo '======================================'
\echo 'Replication Check Complete'
\echo '======================================'


