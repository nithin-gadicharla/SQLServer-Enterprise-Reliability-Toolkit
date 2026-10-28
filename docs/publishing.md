# Publishing this prepared project

The repository and release are not published merely because this file exists. Use the authenticated GitHub account intended to own the public project, inspect the staged files, and preserve source provenance and existing license notices. Do not overwrite an existing repository with the same name without inspection.

With GitHub CLI authenticated and local Git history established:

```bash
gh api user --jq .login
gh repo create SQLServer-Enterprise-Reliability-Toolkit --public --source . --remote origin --push
```

If a repository already exists, inspect it and reconcile its history instead. Wait for the validation workflow, examine failed logs, and fix any issues. Then dispatch the release workflow from main:

```bash
gh workflow run release.yml --ref main
```

The release workflow reruns validation and only publishes v0.2.0 as a prerelease after all jobs succeed. It creates the tag on the triggering source commit and uploads the deterministic ZIP and SHA256SUMS. No historical v0.1.0 public release is fabricated. Check the resulting public repository URL, release URL, asset digest, target commit and workflow conclusion before reporting publication complete. Enable private vulnerability reporting and branch protection separately when supported by the account; those settings are not established by source files.
