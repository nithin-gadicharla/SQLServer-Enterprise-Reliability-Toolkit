# Technical contribution ledger

This ledger records inspectable changes, not a determination of originality or field-wide significance.

| Change from supplied v0.1.0 | Files | Verification |
| --- | --- | --- |
| Preserve heterogeneous result sets, empty schema and NULL | powershell/Toolkit.psm1, fleet runner | Pester serialization tests; SQL lab assertions |
| Correct AG database identity and unknown visibility | sql/02_ag_health.sql | Parser; multi-replica acceptance still required |
| Retain striped backup evidence and safe opt-in verification | sql/03_backup_freshness.sql, Test-SqlBackup.ps1 | Quoting tests; real media verification gate |
| Add performance and visible security inventories | sql/04_performance.sql, sql/05_security_audit.sql | Parser and defined SQL lab job |
| Make synthetic experiment reproducible | benchmarks/ | Generator, raw-trial capture and tested statistics summarizer |
| Expose source and impact evidence honestly | docs/provenance.json, adoption policy | Source archive SHA-256 and independent reports when available |

The implementation was prepared with AI assistance. Repository ownership alone does not demonstrate personal authorship of every line. Maintainers should record their own design proposals, reviewed commits, test execution, technical explanations, and substantive improvements using authenticated Git history and linked reviews. Do not backdate history or describe the supplied archive as a previously published release without evidence.

For a portfolio evidence index, add verified commit links, signed release artifacts, third-party technical reviews, benchmark replication reports, and independently authored adoption accounts. Keep the claimed contribution, author's actual role, technical evidence, and external significance in separate fields. The toolkit itself does not establish eligibility for any immigration classification.
