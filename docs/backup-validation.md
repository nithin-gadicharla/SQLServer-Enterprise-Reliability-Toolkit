# Backup validation and recovery evidence

Three distinct evidence levels must remain separate:

1. **Inventory**: local msdb history, checksum metadata, media stripes, backup set position, encryption/key dependencies. Missing records mean unknown.
2. **Media verification**: explicit `RESTORE VERIFYONLY` with all disk stripes, correct FILE position, CHECKSUM and STOP_ON_ERROR. Missing backup checksums intentionally fail. Success establishes the checks performed by SQL Server, not database structural integrity or successful recovery.
3. **Restore drill**: restore the full/differential/log chain to an isolated instance with unique database and file paths, recover to the required point, run DBCC CHECKDB, validate application invariants, and record measured recovery time and recovered transaction boundary. This release does not automate restore drills.

Do not select arbitrary media automatically from production history. Confirm backup type, media family, stripe count, FILE position, retention and SQL Server service-account access. TDE backups need the correct certificates/keys available on the isolated restore host. VERIFYONLY supports only explicit DISK media in this release; URLs, tapes and snapshots need separate workflows.

For each real drill retain: operator, UTC start/end, tool version and commit, SQL build/edition, database/backup identifiers (redacted publicly), complete chain, checksum state, verification result, restore transcript, CHECKDB result, application validation, interruptions, and cleanup. Compute RTO only from the defined complete recovery procedure; last_commit_time and queue size do not measure RPO.

Manual acceptance matrix: striped full with checksums; non-first backup position; missing stripe; truncated media; checksum-free backup rejected; unavailable encryption key; differential/log chain restore; AG secondary offloaded history. Record pass/fail and evidence paths per case. Untested cases remain unverified.
