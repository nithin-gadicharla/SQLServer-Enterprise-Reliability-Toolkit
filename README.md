# SQL Server Enterprise Reliability Toolkit

Read-only fleet diagnostics for SQL Server, with explicit collection evidence, lossless multi-result JSON reports, opt-in backup verification, and a reproducible lab benchmark.

**Version 0.2.0 — early release candidate.** Derived from the supplied v0.1.0 archive. Production certification, multi-replica AG validation, independent adoption, and performance improvements are not claimed. See [validation status](docs/validation.md).

## Capabilities

| Component | Evidence collected | Important limit |
| --- | --- | --- |
| Instance health | Version, startup, capacity, allocations, wait snapshot | Cumulative observations |
| Always On | Replica connectivity, database synchronization, suspension, send/redo queues | Run on every replica; missing visibility is unknown |
| Backup inventory | Local history, ages, checksum flags, latest full media stripes | History does not establish recoverability |
| Performance | Waits, file I/O, cached query aggregates, current blocking | No query text; snapshots are not interval rates |
| Security | Visible logins, role memberships, grants, configuration, audits | Server metadata only; not a compliance assessment |
| Backup verification | Explicit disk stripes and set position, required checksums | High I/O; does not restore or run CHECKDB |

## Run an assessment

PowerShell 7.2+; SQL Server 2016–2022 are design targets. SQL Server 2022 has an automated lab job; only executed results in the validation record establish tested support. Azure SQL Database is not supported. Managed Instance requires separate validation.

```powershell
# Integrated authentication; SQL Server certificate must chain to a trusted CA and match the name.
./powershell/Invoke-SqlFleetAssessment.ps1 -Instances 'sql01.example.com','sql02.example.com' -OutputDirectory ./reports

# Optional SQL authentication, entered interactively rather than stored in source.
$credential = Get-Credential
./powershell/Invoke-SqlFleetAssessment.ps1 -Instances 'sql01.example.com' -Credential $credential
```

Reports live under a unique run directory; filenames use a hash of the instance identity. JSON retains each result set's columns and rows, including empty schemas and NULLs. Reports still contain sensitive names: hashing filenames is not anonymization. Collection success means the SQL batch completed, not that the server is healthy. Any failed check makes the runner exit 1 after writing the summary.

```powershell
# SQL Server host paths, all stripes, correct backup set position. Explicit opt-in.
./powershell/Test-SqlBackup.ps1 -Instance 'sql01.example.com' -BackupPaths 'D:\backup\stripe1.bak','E:\backup\stripe2.bak' -Position 1 -WhatIf
# Remove -WhatIf after reviewing scope. The command prompts before verification.
```

See [operations and permissions](docs/operations.md), [backup recovery protocol](docs/backup-validation.md), [benchmark instructions](benchmarks/README.md), and [contributing](CONTRIBUTING.md).

## Validate and reproduce

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Invoke-Pester -Path tests/Toolkit.Tests.ps1 -CI
```

```bash
python -m pip install -r requirements-dev.txt
python -m sqlfluff parse --dialect tsql sql/
python -m sqlfluff parse --dialect tsql benchmarks/setup.sql
python -m unittest discover -s tests -p 'test_*.py' -v
python scripts/package.py
```

GitHub Actions defines static parsing, Windows/Linux PowerShell tests, and a disposable SQL Server 2022 TLS integration job. Workflows are test definitions until a linked run confirms their results. Release packaging is deterministic for a fixed file tree and produces SHA-256 checksums.

## Contribution and impact evidence

The [source provenance](docs/provenance.json), [technical contribution ledger](docs/contributions.md), [decision record](docs/design.md), and [adoption policy](docs/adoption.md) separate implementation history from external impact. No usage, stars, citations, endorsements, original research novelty, or immigration outcome is implied. Third-party reports must be independently authored and linked with permission. AI assistance is disclosed; the maintainer must substantiate their own contributions.

MIT license; original notice preserved. See [security reporting](SECURITY.md).
