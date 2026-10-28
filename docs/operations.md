# Operations and permissions

The collector runs five sequential SQL batches per distinct instance in master. It does not fail over replicas, alter configuration, install objects, clear caches, or restore databases. Sequential execution limits concurrency but is not zero overhead: msdb history and cached query DMV scans can be expensive. Pilot with a query timeout and measure duration before scheduling. Avoid polling large estates at high frequency.

## Access matrix

| Check | Permission planning |
| --- | --- |
| Instance and performance DMVs | SQL Server 2016–2019 generally VIEW SERVER STATE; SQL Server 2022 performance DMVs require VIEW SERVER PERFORMANCE STATE |
| HADR DMVs | VIEW SERVER STATE on earlier targets; SQL Server 2022 HADR monitoring may require VIEW SERVER PERFORMANCE STATE; verify every selected DMV against target version |
| Backup inventory | Read access to the selected msdb backupset/backupmediafamily objects and visibility of user databases |
| Security metadata | VIEW ANY DEFINITION on older versions; SQL Server 2022 granular security-definition permissions may be needed; sys.sql_logins and audit metadata have additional visibility rules |
| VERIFYONLY | Separate approved backup validation identity; RESTORE authorization per SQL Server version and deployment policy |

Do not grant sysadmin simply to make collection pass. Validate the minimum permissions in a representative lab, using module signing or a controlled reporting endpoint where appropriate. Partial metadata visibility can return incomplete rows without an error. Collection completion never proves full coverage. No automated least-privilege grants are shipped.

Connections explicitly require encryption and certificate validation. Configure a trusted server certificate and matching DNS name; there is no certificate-bypass switch. Integrated authentication on Linux needs separately configured Kerberos; SQL credentials can be supplied with PSCredential. Credentials are never written to reports. Error text is redacted by default; exception type is retained. Investigate failures with locally authorized tools.

## Interpret observations

- SQL timestamps from msdb and some DMVs use server local time. Report envelope times are UTC. Do not combine them without a known timezone.
- Collect AG data on primary and secondaries. Remote replica state can be absent or stale. Database names use group_database_id through availability_databases_cluster, not remote database_id resolution. Asynchronous SYNCHRONIZING is not automatically a fault. Queues in KB are not measured RPO/RTO.
- Wait and I/O counters require paired snapshots. Discard deltas after restart/reset, negative deltas, missing rows, or instance identity changes. Average read stall is delta(io_stall_read_ms)/delta(num_of_reads), only when reads are positive. Query cache rows disappear and recompile; averages are workload-dependent.
- Backup age is informational: choose policy thresholds for each database's actual RPO, backup design, and AG backup preference. SIMPLE databases have no log-age assessment. Backup history is instance-local and may be purged. Database renames/recreation and offloaded backups make name-based history imperfect.
- Security flags identify review candidates, not findings of compromise. Database-level users, effective permissions, nested directory groups, external identities, and all audit destinations are outside current scope.

Secure report directories with operating system ACLs; review topology and principal names before publishing. No telemetry or automatic uploads are implemented. Remove reports according to your retention policy.

## Authoritative references

- https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-objects/sys-dm-hadr-database-replica-states-transact-sql
- https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-stats-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-verifyonly-transact-sql
- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-arguments-transact-sql
