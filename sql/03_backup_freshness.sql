/* Instance-local history only. Timestamps use SQL Server local time. */
SET NOCOUNT ON;
DECLARE @now datetime = GETDATE();
WITH latest AS (
    SELECT database_name,
           MAX(CASE WHEN type = 'D' AND is_copy_only = 0 THEN backup_finish_date END) AS last_full,
           MAX(CASE WHEN type = 'I' THEN backup_finish_date END) AS last_differential,
           MAX(CASE WHEN type = 'L' THEN backup_finish_date END) AS last_log
    FROM msdb.dbo.backupset
    GROUP BY database_name
)
SELECT d.name AS database_name, d.recovery_model_desc, d.state_desc,
       l.last_full, l.last_differential, l.last_log,
       DATEDIFF_BIG(MINUTE, l.last_full, @now) AS full_age_minutes,
       CASE WHEN d.recovery_model_desc = 'SIMPLE' THEN NULL
            ELSE DATEDIFF_BIG(MINUTE, l.last_log, @now) END AS log_age_minutes,
       CASE WHEN l.last_full IS NULL THEN 'UNKNOWN_NO_LOCAL_FULL_HISTORY'
            ELSE 'HISTORY_PRESENT_NOT_RESTORE_PROOF' END AS evidence_status
FROM sys.databases AS d
LEFT JOIN latest AS l ON l.database_name = d.name
WHERE d.database_id > 4 AND d.source_database_id IS NULL
ORDER BY d.name;
/* Latest full per database, including checksum and media evidence; all stripes retained. */
WITH ranked AS (
    SELECT database_name, backup_set_id, media_set_id, backup_finish_date,
           has_backup_checksums, is_damaged, is_copy_only, position,
           ROW_NUMBER() OVER (PARTITION BY database_name ORDER BY backup_finish_date DESC, backup_set_id DESC) AS rn
    FROM msdb.dbo.backupset WHERE type = 'D'
)
SELECT b.database_name, b.backup_set_id, b.backup_finish_date,
       b.has_backup_checksums, b.is_damaged, b.is_copy_only, b.position,
       m.family_sequence_number, m.device_type, m.physical_device_name
FROM ranked AS b
JOIN msdb.dbo.backupmediafamily AS m ON b.media_set_id = m.media_set_id
WHERE b.rn = 1
ORDER BY b.database_name, m.family_sequence_number;
