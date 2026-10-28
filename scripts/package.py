"""Reproducible ZIP from project sources with fixed timestamps and SHA-256 manifest."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text().strip()
out = root / "artifacts"
out.mkdir(exist_ok=True)
archive = out / f"SQLServer-Enterprise-Reliability-Toolkit-v{version}.zip"
excluded = {".git", "artifacts", "reports", "__pycache__", ".pytest_cache"}
source_dirs = {".github", "sql", "powershell", "tests", "docs", "benchmarks", "scripts"}
root_files = {"README.md", "LICENSE", "VERSION", ".gitignore", "requirements-dev.txt", "CONTRIBUTING.md", "SECURITY.md", "CHANGELOG.md"}
source_extensions = {".sql", ".ps1", ".psm1", ".py", ".md", ".json", ".yml", ".yaml", ".txt"}
files = sorted(p for p in root.rglob("*") if p.is_file() and not p.is_symlink()
               and not excluded.intersection(p.relative_to(root).parts)
               and (p.relative_to(root).as_posix() in root_files
                    or (p.relative_to(root).parts[0] in source_dirs and p.suffix in source_extensions)))
with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for path in files:
        info = zipfile.ZipInfo("SQLServer-Enterprise-Reliability-Toolkit/" + path.relative_to(root).as_posix(), (1980,1,1,0,0,0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, path.read_bytes(), compresslevel=9)
    manifest = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    info = zipfile.ZipInfo("SQLServer-Enterprise-Reliability-Toolkit/SOURCE_MANIFEST.json", (1980,1,1,0,0,0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    z.writestr(info, json.dumps(manifest, indent=2, sort_keys=True) + "\n", compresslevel=9)
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(out / "SHA256SUMS").write_text(f"{digest}  {archive.name}\n")
print(archive)
print(digest)
