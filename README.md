# SQL Server Enterprise Reliability Toolkit

Open-source, **read-only** diagnostics for SQL Server infrastructure, designed for fleet assessments and reproducible operational reporting.

## Included in v0.1.0
- Instance metadata, file allocation and wait-stat snapshots (`sql/01_instance_health.sql`)
- Availability Group replica and database synchronization checks (`sql/02_ag_health.sql`)
- Backup-history freshness inventory (`sql/03_backup_freshness.sql`)
- PowerShell fleet runner with per-check CSV outputs and failure summary (`powershell/Invoke-SqlFleetAssessment.ps1`)

## Quick start
Install the official `SqlServer` PowerShell module and use an account with appropriate read permissions. Test on a non-production instance first.

```powershell
Install-Module SqlServer -Scope CurrentUser
./powershell/Invoke-SqlFleetAssessment.ps1 -Instances 'sql01','sql02' -OutputDirectory './reports'
```

## Requirements and caveats
- SQL Server 2016+ recommended; AG queries require AG-enabled instances and relevant permissions.
- The collector uses integrated authentication; do not store passwords in scripts.
- SQL queries are read-only. They do **not** trigger failovers, alter settings, or perform restores.
- AG queue sizes are reported in KB and are not, by themselves, an RPO/RTO measurement.
- `msdb` backup history can be purged or incomplete; external backup tooling may not be represented.
- Wait stats are cumulative since reset and should be interpreted using time-delta snapshots.
- Some queries return multiple result sets; `Invoke-Sqlcmd` output behavior may differ by version. For precise ingestion, execute each result set separately or use a data-access API.
- Review exported CSV files before sharing: server and database names may be sensitive.

## Roadmap
Query Store regression detection, permission auditing, restore-test evidence, Azure SQL variants, deterministic scoring, and CI integration.

## Contributions and impact
Issues, peer-reviewed pull requests, benchmark methodology, and independent adoption reports are welcome. Only verifiable evidence should be used to describe external impact.

## Security
Never submit production credentials, connection strings, customer data, or confidential topology in issues. Report vulnerabilities privately to the maintainer.

## License
MIT; see LICENSE.
