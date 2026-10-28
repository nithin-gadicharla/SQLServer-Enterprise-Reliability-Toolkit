/* Read-only instance health snapshot. SQL Server 2016+ target; see docs/operations.md for permissions. */
SET NOCOUNT ON;
SELECT @@SERVERNAME AS instance_name, SYSDATETIMEOFFSET() AS collected_at,
       SERVERPROPERTY('ProductVersion') AS product_version,
       SERVERPROPERTY('Edition') AS edition,
       SERVERPROPERTY('IsHadrEnabled') AS hadr_enabled;
SELECT sqlserver_start_time, cpu_count, physical_memory_kb/1024 AS physical_memory_mb
FROM sys.dm_os_sys_info;
SELECT DB_NAME(database_id) AS database_name, type_desc,
       CAST(SUM(CONVERT(bigint, size))*8.0/1024 AS decimal(18,2)) AS allocated_mb
FROM sys.master_files GROUP BY database_id,type_desc ORDER BY database_name,type_desc;
SELECT TOP (20) wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE waiting_tasks_count > 0 AND wait_type NOT LIKE 'SLEEP%'
ORDER BY wait_time_ms DESC;
