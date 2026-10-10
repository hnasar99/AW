#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
flutter pub get --enforce-lockfile
flutter analyze
flutter test
python3 -m unittest discover -s scripts/tests -p test_inspect_apk.py
bash scripts/build_android_rust.sh arm64-v8a
flutter build apk --release --flavor qa --target-platform android-arm64
case "$(uname -s)" in
  Linux) ndk_host=linux-x86_64 ;;
  Darwin) ndk_host=darwin-x86_64 ;;
  *) printf 'Use scripts/build_android.ps1 on Windows.\n' >&2; exit 1 ;;
esac
python3 scripts/inspect_apk.py build/app/outputs/flutter-apk/app-qa-release.apk \
  --readelf "${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/$ndk_host/bin/llvm-readelf" \
  --aapt2 "${ANDROID_SDK_ROOT:-${ANDROID_HOME:?Set ANDROID_HOME or ANDROID_SDK_ROOT}}/build-tools/36.0.0/aapt2" \
  --pubspec pubspec.yaml --flavor qa \
  --output artifacts/apk-inspection.json
