#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
if [[ "$(uname -s)" != Darwin ]]; then
  printf 'An Apple SDK and macOS host are required to build the iOS library.\n' >&2
  exit 1
fi
target="${1:-aarch64-apple-ios}"
case "$target" in
  aarch64-apple-ios|aarch64-apple-ios-sim|x86_64-apple-ios) ;;
  *) printf 'Unsupported iOS target: %s\n' "$target" >&2; exit 1 ;;
esac
bash scripts/prepare_upstream.sh
rustup target add "$target"
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
cargo build --locked --release --target "$target" -p arc_openhuman_bridge
printf '\nStatic library: %s\n' "$project_root/target/$target/release/libarc_openhuman_bridge.a"
printf 'This creates the Rust library only; an iOS Runner, signing and device validation are still required.\n'
