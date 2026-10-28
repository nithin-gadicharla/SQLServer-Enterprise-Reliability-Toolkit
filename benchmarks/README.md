# Reproducible synthetic index experiment

This benchmark demonstrates a repeatable diagnostic method. It does not establish toolkit overhead, production throughput, or a novel indexing algorithm. Measured raw trials and results are available in [ci-40624040335](results/ci-40624040335/README.md), linked to their exact source commit and hosted run. They are synthetic maintainer experiments, not independent adoption.

Use an isolated SQL Server Developer instance with a trusted certificate. `setup.sql` creates the reserved `ToolkitBenchmark` database and 100,000 deterministic rows; it refuses an existing database. Run the script using SSMS or sqlcmd (it contains GO). Do not run it on production. Record source commit, SQL build/edition, CPU/memory/storage, VM/container limits, host load, timezone, client runtime and driver, and certificate configuration.

```powershell
$credential = Get-Credential
./benchmarks/Run-Benchmark.ps1 -Instance 'localhost,1433' -Credential $credential -Trials 10
```

The runner executes COUNT_BIG for bucket 42 before and after adding a nonclustered index, using MAXDOP 1, two warmups per phase, and at least five timed trials. It asserts the same 100 rows in both phases. Client elapsed time includes transport and materialization; raw SQL STATISTICS IO/TIME messages are retained per trial. Those messages are locale-dependent and are not parsed into invented metrics. No shared cache is flushed. Index build time and storage cost are outside query timings and should be measured separately for an adoption decision.

```bash
python benchmarks/summarize.py artifacts/benchmark/<run-id>/raw.json
```

The summary reports count, median, min and max per phase and median reduction, retaining negative regressions. Keep raw.json with summaries, SQL plans and the exact source commit. Fixed before/after order can confound time trends; repeat fresh labs, alternate order in a separately documented protocol, include warm/cold workload definitions, and report all runs. Do not generalize a synthetic single-client result to other workloads.

Cleanup is deliberately manual after evidence collection: inspect `ToolkitBenchmark`, disconnect lab sessions, and drop that database only in the disposable lab. Recreate the lab before rerunning; the runner refuses a pre-existing benchmark index.
