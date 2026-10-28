# Contributing

Open an issue with a sanitized reproduction and affected SQL/PowerShell versions. For changes, explain the operational problem, why the new behavior helps, permissions and overhead, and the evidence supporting it. Small corrections are welcome.

Run SQLFluff parsing, Python unit tests and Pester. SQL changes need live target-version validation when feasible; AG changes need primary/secondary topology evidence, including disconnected, suspended, asynchronous and missing-visibility cases. Security changes need restricted-identity coverage. State unexecuted tests explicitly. Never attach production credentials, customer data or topology.

Keep source provenance, MIT notices, AI assistance disclosures and contributor attribution accurate. Do not claim independent adoption through maintainer-authored examples. Use pull requests for review. The maintainer should enable branch protection and required CI after the first passing workflow; this repository does not claim those settings are already configured.
