/* Read-only backup history; absence of history does not prove absence of backups. */
SET NOCOUNT ON;
WITH latest AS (
 SELECT database_name, type, MAX(backup_finish_date) AS last_finish
 FROM msdb.dbo.backupset WHERE is_copy_only=0 GROUP BY database_name,type
)
SELECT d.name AS database_name,d.recovery_model_desc,d.state_desc,
 MAX(CASE WHEN l.type='D' THEN l.last_finish END) AS last_full,
 MAX(CASE WHEN l.type='I' THEN l.last_finish END) AS last_differential,
 MAX(CASE WHEN l.type='L' THEN l.last_finish END) AS last_log
FROM sys.databases d LEFT JOIN latest l ON d.name=l.database_name
WHERE d.database_id>4
GROUP BY d.name,d.recovery_model_desc,d.state_desc ORDER BY d.name;
