/* Cumulative snapshots, not interval rates. Query text intentionally excluded. */
SET NOCOUNT ON;
SELECT SYSDATETIMEOFFSET() AS collected_at, sqlserver_start_time
FROM sys.dm_os_sys_info;
SELECT wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms
FROM sys.dm_os_wait_stats WHERE waiting_tasks_count > 0;
SELECT database_id, file_id, num_of_reads, num_of_writes,
       io_stall_read_ms, io_stall_write_ms, num_of_bytes_read, num_of_bytes_written,
       sample_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL);
SELECT TOP (25) query_hash, plan_generation_num, creation_time, last_execution_time,
       execution_count, total_worker_time AS total_cpu_us,
       total_elapsed_time AS total_elapsed_us, total_logical_reads,
       CONVERT(decimal(28,2), total_worker_time / NULLIF(CONVERT(decimal(28,2), execution_count), 0)) AS mean_cpu_us
FROM sys.dm_exec_query_stats
ORDER BY total_worker_time DESC, query_hash;
SELECT session_id, blocking_session_id, database_id, status, wait_type,
       wait_time AS current_wait_ms, cpu_time AS cpu_ms, total_elapsed_time AS elapsed_ms
FROM sys.dm_exec_requests
WHERE session_id <> @@SPID AND session_id > 50;
