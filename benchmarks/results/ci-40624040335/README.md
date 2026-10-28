# Measured synthetic index experiment

Source commit: [30b70f4](https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/commit/30b70f4ae16734db61bdd77ce467cc204fc07896).
Successful hosted run: https://github.com/nithin-gadicharla/SQLServer-Enterprise-Reliability-Toolkit/actions/runs/40624040335
Artifact ID: 12788955886. Original artifact ZIP SHA-256: 63060e6f3f997a51aebfef18456b098688f6162fd7e58a8dc52199f28c998429.

Raw JSON and summary are copied from the hosted artifact with JSON whitespace normalized only. Values and messages are retained. This experiment is maintainer-controlled synthetic evidence, not independent adoption or a third-party replication.

| Observation | Before index | After index |
| --- | --- | --- |
| Trials after two warmups | 10 | 10 |
| Median client elapsed (ms) | 7.54725 | 0.85745 |
| Minimum client elapsed (ms) | 7.12 | 0.716 |
| Maximum client elapsed (ms) | 8.2158 | 3.4856 |
| Workload logical reads per trial | 2714 | 2 |
| Matching rows | 100 | 100 |

Median client elapsed reduction was 88.6389% in this single synthetic run. That is an index experiment result under these conditions, not a toolkit speedup, production throughput gain, general performance guarantee, or novel indexing algorithm. Physical reads were zero in these warm-cache trials. Fixed phase order, one client, shared hosted hardware, small timings, and unmeasured index storage/build costs limit interpretation. The run with incomplete IO capture is preserved separately in ci-40623696963.

Environment: SQL Server Developer 2022 CU18, build 16.0.4185.3; Linux SQL container on Ubuntu 22.04.5, hosted Ubuntu 24.04.5 client, PowerShell 7.6.9; SQL reported 4 CPUs and 13,093,888 KB physical memory. Container image digest and workflow are pinned in the source commit. Host storage latency and co-tenant load were not controlled or independently measured. See raw.json and ../../README.md for the method and limits.

Recompute summary: `python benchmarks/summarize.py benchmarks/results/ci-40624040335/raw.json`.
