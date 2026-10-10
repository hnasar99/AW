#!/usr/bin/env python3
"""Apply audited patches only to their exact upstream revision."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess


def apply() -> None:
    root = Path(__file__).resolve().parents[1]
    if not (root / ".git").exists():
        # Archives contain the already patched source. Verify every recorded
        # byte and the exact upstream file set; do not infer success from git
        # failure or attempt to apply the patches twice.
        from package_corresponding_source import verify_archive

        result = verify_archive(root)
        print(f"Verified pre-applied archive: {result['files']} files, "
              f"{result['repositories']} repositories.")
        return
    entries = json.loads((root / "patches/manifest.json").read_text())
    for entry in entries:
        repository = (root / entry["repository"]).resolve()
        patch = (root / entry["patch"]).resolve()
        if not repository.is_relative_to(root) or not patch.is_relative_to(root):
            raise RuntimeError("Patch paths must remain inside the project.")
        revision = subprocess.check_output(
            ["git", "-C", str(repository), "rev-parse", "HEAD"], text=True
        ).strip()
        if revision != entry["upstream_commit"]:
            raise RuntimeError(f"Unexpected upstream commit in {entry['repository']}")
        if hashlib.sha256(patch.read_bytes()).hexdigest() != entry["sha256"]:
            raise RuntimeError(f"Patch checksum mismatch: {entry['patch']}")
        command = ["git", "-C", str(repository), "apply"]
        already = subprocess.run(
            command + ["--reverse", "--check", str(patch)], capture_output=True
        )
        if already.returncode == 0:
            print(f"Already applied: {entry['patch']}")
            continue
        subprocess.run(command + ["--check", str(patch)], check=True)
        subprocess.run(command + [str(patch)], check=True)
        print(f"Applied: {entry['patch']}")


if __name__ == "__main__":
    apply()
