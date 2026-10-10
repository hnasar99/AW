#!/usr/bin/env bash
# Build the actual embedded runtime for the requested Android ABI.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
abi="${1:-arm64-v8a}"
case "$abi" in
  arm64-v8a) rust_target=aarch64-linux-android ;;
  x86_64) rust_target=x86_64-linux-android ;;
  *) echo "Supported ABIs: arm64-v8a, x86_64" >&2; exit 2 ;;
esac
command -v cargo-ndk >/dev/null || { echo "Install cargo-ndk 4.1.2 with cargo install cargo-ndk --version 4.1.2 --locked." >&2; exit 1; }
bash scripts/prepare_upstream.sh
rustup target add "$rust_target"
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
# The bridge's build.rs also sets common-page-size on its final Android link.
# Verify both PT_LOAD and the end of PT_GNU_RELRO before promoting any output.
export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-z,max-page-size=16384"
stage_dir="$(mktemp -d)"
trap 'rm -rf "$stage_dir"' EXIT
cargo ndk --platform 26 -t "$abi" -o "$stage_dir" \
  build --locked --release -p arc_openhuman_bridge
source_library="$stage_dir/$abi/libarc_openhuman_bridge.so"
test -s "$source_library"
python3 - "$source_library" "$abi" <<'PY'
import json
import os
from pathlib import Path
import re
import subprocess
import sys

sys.path.insert(0, str(Path("scripts").resolve()))
from inspect_apk import EXPECTED, elf_load_alignment

library = Path(sys.argv[1])
abi = sys.argv[2]
machine, loads, relro_ends = elf_load_alignment(library.read_bytes())
if machine != {"arm64-v8a": 183, "x86_64": 62}[abi]:
    raise SystemExit(f"Wrong ELF architecture for {abi}: {machine}")
if any(value < 16384 for value in loads):
    raise SystemExit(f"PT_LOAD does not support 16 KiB pages: {loads}")
if not relro_ends or any(value % 16384 for value in relro_ends):
    raise SystemExit(f"PT_GNU_RELRO end is not 16 KiB aligned: {relro_ends}")
ndk = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_ROOT")
if not ndk:
    raise SystemExit("Set ANDROID_NDK_HOME to the pinned NDK directory.")
readelfs = sorted(Path(ndk).glob("toolchains/llvm/prebuilt/*/bin/llvm-readelf"))
if not readelfs:
    raise SystemExit("The configured Android NDK has no llvm-readelf executable.")
readelf = str(readelfs[0])
dynamic = subprocess.check_output([readelf, "--dynamic", str(library)], text=True)
needed = set(re.findall(r"\(NEEDED\).*?\[([^\]]+)\]", dynamic))
# The chosen Rust crates are linked into the bridge as rlibs. Their extra
# cdylib build products are not Android runtime dependencies of this ABI.
# Fail if that changes, instead of silently omitting a required shared object.
if not needed or needed - {"libc.so", "libm.so", "libdl.so"}:
    raise SystemExit(f"Review unexpected Android shared dependencies: {sorted(needed)}")
symbols = subprocess.check_output([readelf, "--dyn-syms", "--wide", str(library)], text=True)
exports = {line.split()[-1] for line in symbols.splitlines()
           if " GLOBAL " in line and " UND " not in line}
if EXPECTED - exports:
    raise SystemExit(f"Missing C ABI functions: {sorted(EXPECTED - exports)}")
print(json.dumps({"abi": abi, "load_alignments": loads,
                  "relro_end_addresses": relro_ends,
                  "needed": sorted(needed), "verified_exports": sorted(EXPECTED)}))
PY
# Override the output directory to build a reviewable candidate without
# touching JNI inputs while Gradle is packaging another artifact.
output_dir="${ARC_NATIVE_OUTPUT_DIR:-android/app/src/main/jniLibs}/$abi"
mkdir -p "$output_dir"
install -m 0644 "$source_library" "$output_dir/libarc_openhuman_bridge.so"
# Earlier versions copied cargo-ndk's auxiliary cdylib products as well.
# Their rlib implementations are already inside the verified bridge above.
rm -f "$output_dir/libtinymcp.so" "$output_dir/libtinyconnectors.so"
printf 'Verified Android bridge: %s\n' "$output_dir/libarc_openhuman_bridge.so"
