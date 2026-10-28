/* Read-only; run on every replica. Missing DMV rows are unknown, never healthy. */
SET NOCOUNT ON;
IF COALESCE(CONVERT(int, SERVERPROPERTY('IsHadrEnabled')), 0) <> 1
BEGIN
    SELECT 'NOT_APPLICABLE' AS collection_status, 'HADR disabled' AS reason;
    RETURN;
END;
SELECT ag.name AS availability_group, ar.replica_server_name,
       ar.availability_mode_desc, ars.is_local, ars.role_desc,
       ars.connected_state_desc, ars.synchronization_health_desc,
       CASE WHEN ars.replica_id IS NULL THEN 'UNKNOWN'
            WHEN ars.connected_state_desc = 'DISCONNECTED' THEN 'WARNING'
            WHEN ars.synchronization_health_desc = 'NOT_HEALTHY' THEN 'WARNING'
            ELSE 'OBSERVED' END AS observation_status
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states AS ars
    ON ar.replica_id = ars.replica_id
ORDER BY ag.name, ar.replica_server_name;
SELECT ag.name AS availability_group, ar.replica_server_name,
       adc.database_name, drs.is_local, drs.synchronization_state_desc,
       drs.synchronization_health_desc, drs.is_suspended, drs.suspend_reason_desc,
       drs.log_send_queue_size AS log_send_queue_kb,
       drs.redo_queue_size AS redo_queue_kb,
       drs.log_send_rate AS log_send_rate_kb_sec,
       drs.redo_rate AS redo_rate_kb_sec, drs.last_commit_time,
       CASE WHEN drs.replica_id IS NULL THEN 'UNKNOWN'
            WHEN drs.is_suspended = 1 THEN 'WARNING'
            WHEN drs.synchronization_health_desc = 'NOT_HEALTHY' THEN 'WARNING'
            ELSE 'OBSERVED' END AS observation_status
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id
JOIN sys.availability_databases_cluster AS adc ON ag.group_id = adc.group_id
LEFT JOIN sys.dm_hadr_database_replica_states AS drs
    ON drs.replica_id = ar.replica_id AND drs.group_database_id = adc.group_database_id
ORDER BY ag.name, ar.replica_server_name, adc.database_name;
