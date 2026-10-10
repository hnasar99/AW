#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v cargo-ndk >/dev/null || { echo "Install cargo-ndk: cargo install cargo-ndk" >&2; exit 1; }
rustup target add aarch64-linux-android armv7-linux-androideabi
mkdir -p android/app/src/main/jniLibs
cargo ndk -t arm64-v8a -t armeabi-v7a \
  -o android/app/src/main/jniLibs \
  build --release --manifest-path rust/arc_openhuman_bridge/Cargo.toml
