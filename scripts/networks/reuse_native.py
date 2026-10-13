#!/usr/bin/env python3
"""Reuse ONLY a hash-verified unchanged ARM64 bridge; rebuild Flutter/Dart.

The known artifact digest authenticates the exact previously inspected inputs.
This does not claim native compilation or Android runtime execution in this run.
"""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import zipfile

BASE = '7768c172c38f674c8903f2e35a192167b9b4ee78'
ARTIFACT_SHA256 = 'e1405bc4ca49e69194350e9259be25b3698c83615d5dcea99fc0e29767bd0ed0'
ROOT = Path(__file__).resolve().parents[2]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def unique(archive, suffix):
    names = [n for n in archive.namelist() if n == suffix or n.endswith('/' + suffix)]
    if len(names) != 1:
        raise ValueError(f'Expected one archive entry: {suffix}')
    return archive.read(names[0])

def main():
    if len(sys.argv) != 2:
        raise SystemExit('Usage: reuse_native.py BASE_ARTIFACT_ZIP')
    path = Path(sys.argv[1])
    if not 0 < path.stat().st_size <= 100_000_000:
        raise ValueError('Unexpected baseline artifact size')
    data = path.read_bytes()
    if digest(data) != ARTIFACT_SHA256:
        raise ValueError('Baseline artifact digest mismatch')
    # Reject reuse whenever actual native sources, locks, pins or patches differ.
    subprocess.run(['git', '-C', str(ROOT), 'diff', '--exit-code', BASE, 'HEAD', '--',
        'rust/', 'vendor/', 'patches/', 'Cargo.lock', 'Cargo.toml',
        'rust-toolchain.toml', '.gitmodules', 'scripts/build_android_rust.sh'], check=True)
    with zipfile.ZipFile(io.BytesIO(data)) as bundle:
        apk = unique(bundle, 'aw-qa-arm64.apk')
        inspection = json.loads(unique(bundle, 'apk-inspection.json'))
        if digest(apk) != inspection['sha256'] or inspection['static_checks'] != 'passed':
            raise ValueError('Baseline APK does not match its inspected report')
        if unique(bundle, 'Cargo.lock') != (ROOT / 'Cargo.lock').read_bytes():
            raise ValueError('Cargo lock mismatch')
        if unique(bundle, 'pubspec.lock') != (ROOT / 'pubspec.lock').read_bytes():
            raise ValueError('Dart lock mismatch')
    entry = 'lib/arm64-v8a/libarc_openhuman_bridge.so'
    with zipfile.ZipFile(io.BytesIO(apk)) as archive:
        native = archive.read(entry)
    records = [n for n in inspection['native_libraries'] if n['path'] == entry]
    if len(records) != 1 or digest(native) != records[0]['sha256']:
        raise ValueError('Native bridge hash mismatch')
    dest = ROOT / 'android/app/src/main/jniLibs/arm64-v8a/libarc_openhuman_bridge.so'
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(native)
    report = {
        'mode': 'verified-reuse-not-native-rebuild', 'base_commit': BASE,
        'base_run': 38393284826, 'base_artifact': 11812527906,
        'base_artifact_sha256': digest(data), 'base_apk_sha256': digest(apk),
        'bridge_sha256': digest(native), 'source_diff': 'unchanged-native-inputs',
        'scope': 'Flutter AOT rebuilt; Android runtime acceptance remains separate',
    }
    (ROOT / 'artifacts').mkdir(exist_ok=True)
    (ROOT / 'artifacts/native-reuse.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))

if __name__ == '__main__':
    main()
