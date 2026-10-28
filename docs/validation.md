# Validation record

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

First publication should be an explicitly marked prerelease until the live integration job passes. Multi-replica AG, restricted-permission and restore-drill validation remain separate gates before production readiness can be asserted. Link actual hosted CI runs and raw artifact checksums here after execution; do not replace unexecuted statuses with assumptions.
