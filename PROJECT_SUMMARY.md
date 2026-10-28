# SQL Server Enterprise Reliability Toolkit — Project Summary

> **Project highlight:** A small SQL Server diagnostic starter package was expanded into a publicly released, tested toolkit with lossless fleet reporting, explicit evidence limits, checksum-based backup verification, and reproducible technical results.

**Repository:** [SQLServer-Enterprise-Reliability-Toolkit](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit)  
**First public release:** [v0.2.0 prerelease](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/releases/tag/v0.2.0)  
**License:** MIT  
**Release validation:** [Successful workflow run](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40624290588)

## The strongest parts of the project

### 1. Reliable fleet collection without losing result sets

The original runner sent heterogeneous SQL output through a single CSV pipeline, creating a risk of lost or mismatched results. The replacement captures each SQL result set separately in versioned JSON, preserving column names, empty result schemas, and SQL NULL values.

Each check records its query SHA-256, collection time, elapsed time, status, and run identity. A failed check is recorded without stopping the remaining checks, and any collection failure produces a nonzero process exit code. Unique run directories and hashed instance filenames help avoid overwrites and filename collisions.

**Why it matters:** Operators and automated consumers can distinguish complete collection, failed collection, and genuinely empty results. A successful collection is not presented as proof of server health.

**Implementation:** [Fleet runner](powershell/Invoke-SqlFleetAssessment.ps1) · [Shared module](powershell/Toolkit.psm1)

### 2. Always On monitoring that makes uncertainty visible

The Always On checks collect replica connectivity, synchronization health, database synchronization state, suspension reasons, and log-send/redo queue metrics. Remote database names resolve through the AG database identity rather than assuming a remote database ID maps correctly on the local instance.

Missing DMV visibility is reported as **UNKNOWN**, rather than silently classified as healthy. The documentation explains why asynchronous synchronization and queue sizes require context and do not independently measure RPO or RTO.

**Why it matters:** The toolkit avoids reassuring conclusions from incomplete replica visibility. Multi-replica execution remains a separate validation requirement; the hosted lab verified the HADR-disabled branch.

**Implementation:** [Always On diagnostics](sql/02_ag_health.sql) · [Operational guidance](docs/operations.md)

### 3. Backup validation beyond a freshness timestamp

Backup inventory includes local full/differential/log history, ages, checksum metadata, and the media stripes and backup position for the latest full backup. A separate, opt-in PowerShell command runs `RESTORE VERIFYONLY` with explicit disk stripes, `FILE`, `CHECKSUM`, and `STOP_ON_ERROR`.

The live SQL Server lab verified a striped checksummed backup and confirmed rejection of checksum-free media and incomplete stripe sets. The command supports `-WhatIf` and confirmation before verification.

**Why it matters:** Backup history, media readability, and successful recovery are treated as different evidence levels. VERIFYONLY success is not described as a successful restore or a substitute for CHECKDB.

**Implementation:** [Backup inventory](sql/03_backup_freshness.sql) · [Verification command](powershell/Test-SqlBackup.ps1) · [Recovery evidence protocol](docs/backup-validation.md)

### 4. Real tests and reproducible release artifacts

GitHub Actions validates the project using static SQL parsing, Python tests, PowerShell tests on Windows and Linux, and a disposable SQL Server 2022 environment with certificate-validated TLS.

| Validation | Verified result |
| --- | --- |
| PowerShell / Pester | 10 tests passed on Windows and 10 on Linux |
| Python | 5 unit tests passed |
| T-SQL parsing | Five diagnostic scripts and benchmark setup passed |
| Live SQL Server | Diagnostic execution and multi-result serialization passed |
| Backup media | Positive and negative verification cases passed |
| Benchmark evidence | All 20 measured trials retained STATISTICS IO messages |
| Release pipeline | All validation and publication jobs passed |
| Published package | Downloaded ZIP and all 44 source-file checksums verified at publication |

The release pipeline validates its exact source commit before publishing. Packaging produces a source manifest and SHA-256 checksum file. The published ZIP matched the local build byte for byte.

**Evidence:** [Validation record](docs/validation.md) · [CI workflow](.github/workflows/ci.yml) · [Release workflow](.github/workflows/release.yml) · [Packaging script](scripts/package.py)

### 5. Transparent benchmark results with raw evidence

A deterministic lab creates 100,000 rows and measures the same query before and after adding a nonclustered index. Each phase uses two warmups followed by ten measured trials, with identical result counts and raw SQL messages retained.

| Metric | Before index | After index |
| --- | --- | --- |
| Median client elapsed time | 7.54725 ms | 0.85745 ms |
| Logical reads per trial | 2,714 | 2 |
| Matching rows | 100 | 100 |
| Measured trials | 10 | 10 |

**Observed median elapsed reduction: 88.64% in this single synthetic run.** This demonstrates a reproducible indexing experiment; it is not a toolkit speedup, a production performance guarantee, or evidence of a novel indexing algorithm.

The source commit, SQL build, container image digest, runtime, CPU/memory observations, raw trials, and summary are documented. Fixed phase order, warm caches, shared hosted hardware, and unmeasured index build/storage costs limit interpretation.

**Evidence:** [Measured results and limitations](benchmarks/results/ci-40624040335/README.md) · [Raw trials](benchmarks/results/ci-40624040335/raw.json) · [Reproduction instructions](benchmarks/README.md)

## Additional engineering improvements

- **Performance diagnostics:** Wait statistics, file I/O counters, cached query aggregates, and current blocking observations. Query text is intentionally excluded; cumulative counters require interval-aware interpretation.
- **Security auditing:** Visible SQL logins, server role membership, explicit grants, selected configuration settings, database trust/chaining flags, and server audit metadata. This is a metadata inventory, not a complete effective-permissions or compliance assessment.
- **Connection security:** Encrypted connections with certificate validation, safe connection-string construction, and optional credentials supplied through PSCredential.
- **Safer reporting:** Raw exception messages are redacted from persisted reports. Reports still contain topology and principal names and require appropriate access controls.
- **Documentation:** Setup, permissions, interpretation, design decisions, backup recovery evidence, contributions, security reporting, and adoption reporting are included.

## Issues discovered and corrected

The project records corrections rather than hiding failed attempts:

1. Replaced the original multi-result CSV approach with explicit result-set capture.
2. Corrected AG remote database-name resolution.
3. Fixed PowerShell connection-string builder keys that prevented reaching SQL Server.
4. Corrected SQLFluff invocation to parse each supported path separately.
5. Fixed disposable database cleanup by clearing idle test connection pools.
6. Replaced benchmark `ExecuteScalar` collection with a fully drained reader so trailing STATISTICS IO messages are captured; added live assertions to prevent regression.
7. Updated deprecated Actions pins and pinned the tested SQL Server image by digest.

The earlier benchmark run with incomplete IO capture remains available with its limitation documented.

## Contribution and portfolio evidence

The repository preserves the supplied v0.1.0 source baseline separately from subsequent improvements. It includes source archive provenance, a technical contribution ledger, reproducible measurements, public CI history, release assets, and checksums.

These records make the work inspectable and can support a technical portfolio. **AI assistance is disclosed**, and personal authorship or original contribution claims must be supported by the maintainer's actual role, design work, reviewed changes, and evidence. Repository ownership does not establish authorship of every line or field-wide significance.

An adoption policy and voluntary issue template support future independently authored reports. **No usage, stars, citations, endorsements, independent adoption, or immigration outcome has been fabricated or asserted.**

**Evidence:** [Source provenance](docs/provenance.json) · [Contribution ledger](docs/contributions.md) · [Adoption evidence policy](docs/adoption.md)

## Current boundaries and next validation priorities

v0.2.0 is a **prerelease candidate**, not a production certification. The next priorities are multi-replica AG scenarios, restricted-permission coverage, isolated full/differential/log restore drills with CHECKDB and application validation, and additional SQL Server version testing. Azure SQL Database is not supported, and Managed Instance requires separate validation.

Independent replication and actual adoption reports would add external evidence; the existing benchmark and CI runs remain maintainer-controlled technical evidence.
