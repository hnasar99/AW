#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
expected=036b13e79e4e555ae249f6245966f384d15f35ba
if [ -e .git ]; then
  # A failed git check never falls back to the archive path.
  git submodule update --init --recursive vendor/openhuman
  actual="$(git -C vendor/openhuman rev-parse HEAD)"
  test "$actual" = "$expected" || { echo "Unexpected OpenHuman commit: $actual" >&2; exit 1; }
elif [ ! -f SOURCE_MANIFEST.json ]; then
  echo "Expected a git checkout or a verified corresponding-source archive." >&2
  exit 1
fi
python3 scripts/apply_upstream_patches.py
