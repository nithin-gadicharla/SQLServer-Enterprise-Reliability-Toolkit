# Validation record

## Hosted validation, 2026-10-27 America/Chicago

[Run 40624040335](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40624040335) passed on source commit 30b70f4ae16734db61bdd77ce467cc204fc07896. All four jobs succeeded: static, PowerShell on Ubuntu, PowerShell on Windows, and SQL Server 2022 integration.

The hosted run executed all five diagnostic batches over certificate-validated TLS, verified heterogeneous/empty result serialization and HADR-disabled behavior, verified a striped checksummed full backup, rejected checksum-free and incomplete stripe media, executed the synthetic before/after benchmark, asserted STATISTICS IO capture for all 20 trials, and removed its disposable lab databases. Windows and Linux each passed all 10 Pester tests; the static job passed all 5 Python tests and SQL parsing.

Measured evidence: [raw trials and summary](../benchmarks/results/ci-40624040335/README.md). It is a synthetic, maintainer-controlled experiment, not independent adoption. No production overhead, RPO/RTO, multi-replica AG, restricted-identity, restore drill, older SQL version, or Azure MI result is established.

Transparent corrections: [first run 40623469140](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40623469140) failed while dropping the benchmark database because an idle pooled connection remained. The harness now clears its pools before teardown. [Run 40623696963](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40623696963) passed, but artifact review found incomplete trailing IO messages from ExecuteScalar. The benchmark now drains a reader and tests message capture; the earlier client-timing data is retained with that limitation.

The first release is a prerelease candidate. Production certification and independent adoption are not asserted. The release workflow revalidates its exact source commit before publishing.

## Earlier local validation

Local validation performed on 2026-10-27 (America/Chicago), using PowerShell 7.4.6 on Linux and SQLFluff 3.4.2. This record describes local execution, not a GitHub Actions run.

| Check | Result | Evidence / scope |
| --- | --- | --- |
| T-SQL parser | Passed | Five diagnostic files and benchmark setup parsed as tsql; not database compilation |
| PowerShell Pester | 10 passed, 0 failed | Parse scripts/modules; safe connection keys; TLS; string injection; NULL/empty result sets; hashed identity; backup quoting/validation; WhatIf; per-check failures and exit status |
| Python unit tests | 5 passed, 0 failed | Benchmark summaries, zero baseline, regressions, invalid/missing and nonfinite observations |
| Connection probe | Reached network Open | Expected unreachable localhost endpoint; corrected connection-builder failure; not successful SQL authentication |
| Workflow/issue YAML | Parsed | Structural YAML parse, not a hosted Actions execution |
| Package reproducibility | Recorded in validation-local.json | Two local builds must have identical SHA-256 before delivery |
| SQL Server integration | NOT RUN locally | No local SQL Server engine or Docker runtime; workflow defines a disposable SQL 2022 TLS lab |
| Real backup verification | NOT RUN locally | CI harness defines positive/negative striped-media cases; no pass claim |
| Benchmark measurements | NOT RUN locally | No latency reduction or production throughput claim; CI lab captures raw trials when executed |
| Multi-replica AG scenarios | NOT RUN | Requires separate primary/secondary/disconnected/suspended/asynchronous and restricted-visibility lab |
| SQL 2016/2017/2019, Azure MI | NOT RUN | Syntax design targets are not a compatibility certification |
| Restricted identity | NOT RUN | Metadata visibility can silently limit coverage |
| Independent adoption | No evidence verified | See adoption policy; no invented users, stars, citations, or endorsements |

Two defects found and fixed during local validation: PowerShell connection-string dictionary keys prevented reaching SQL Server; and the proposed SQLFluff command accepted only one path, so CI now parses the diagnostics and benchmark separately. The original multi-result CSV loss risk and AG remote database-name issue were corrected in the implementation.

Hosted SQL 2022 integration has since passed as documented above. First publication remains an explicitly marked prerelease because broader topology and recovery validation is incomplete. Multi-replica AG, restricted-permission and restore-drill validation remain separate gates before production readiness can be asserted. Link actual hosted CI runs and raw artifact checksums here after execution; do not replace unexecuted statuses with assumptions.
