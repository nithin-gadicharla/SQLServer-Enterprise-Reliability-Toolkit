# Design decisions

## Multi-result capture

The source runner exported heterogeneous Invoke-Sqlcmd output through one CSV pipeline. The successor uses a DataSet and one JSON envelope per check. Result-set schemas survive empty results; SQL NULL becomes JSON null. Tests cover heterogeneous sets and empty schemas. Binary values use the .NET JSON representation; a general typed interchange schema is not promised.

## Observation versus health

Collection status is operational evidence, not a health score. Missing AG DMV rows become UNKNOWN. Backup history does not silently pass an RPO policy. This avoids manufacturing assurance from partial visibility.

## Authentication and failure handling

Use encrypted validated TLS, connection-string builders and PSCredential. No connection-string interpolation, raw exception messages in reports, or automatic retries of failed verification. Instance filenames use SHA-256 prefixes and every run has a unique ID, preventing legacy sanitizer collisions and report overwrites.

## Bounded operations

Fleet work is sequential with timeouts and isolated per-check failures. Diagnostics are read-only. Backup verification and the destructive benchmark are separate explicit commands with ShouldProcess. No cache flush, automatic failover, remediation, or restore is included.

## Compatibility and limitations

Target 2016–2022 SQL syntax; pin tested SQL 2022 lab configuration in CI. SQL parsing cannot validate permissions, DMV semantics, or AG topology. Multi-replica tests remain a separate gate. System.Data.SqlClient is used from the PowerShell runtime; this is a deliberate minimal dependency choice, not a claim of the latest Microsoft client driver support. Upgrade to Microsoft.Data.SqlClient should include packaging and authentication regression tests.
