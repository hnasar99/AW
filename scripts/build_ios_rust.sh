#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
rustup target add aarch64-apple-ios
cargo build --release --target aarch64-apple-ios --manifest-path rust/arc_openhuman_bridge/Cargo.toml
printf '\nStatic library: %s\n' "$ROOT/rust/arc_openhuman_bridge/target/aarch64-apple-ios/release/libarc_openhuman_bridge.a"
printf 'Add this library to ios/Runner.xcodeproj, Link Binary With Libraries, and add its search path.\n'
