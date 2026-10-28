/* Read-only Always On AG status. Execute on an AG-enabled SQL Server instance. */
SET NOCOUNT ON;
IF CONVERT(int,SERVERPROPERTY('IsHadrEnabled')) <> 1
BEGIN
    PRINT 'Always On Availability Groups are not enabled on this instance.';
    RETURN;
END;
SELECT ag.name AS availability_group, ar.replica_server_name,
       ars.role_desc, ars.operational_state_desc, ars.connected_state_desc,
       ars.synchronization_health_desc
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ag.group_id=ar.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id=ars.replica_id
ORDER BY ag.name,ar.replica_server_name;
SELECT ag.name AS availability_group, ar.replica_server_name,
       DB_NAME(drs.database_id) AS database_name,
       drs.synchronization_state_desc, drs.synchronization_health_desc,
       drs.is_suspended, drs.log_send_queue_size, drs.redo_queue_size,
       drs.last_commit_time
FROM sys.dm_hadr_database_replica_states drs
JOIN sys.availability_replicas ar ON drs.replica_id=ar.replica_id
JOIN sys.availability_groups ag ON drs.group_id=ag.group_id
ORDER BY ag.name,ar.replica_server_name,database_name;
