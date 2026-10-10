# Windows PowerShell: Flutter, Rust and Android SDK/NDK must be installed.
param([ValidateSet('arm64-v8a', 'x86_64')][string]$Abi = 'arm64-v8a')
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
git submodule update --init --recursive vendor/openhuman
if ($LASTEXITCODE -ne 0) { throw 'OpenHuman checkout failed.' }
$pin = git -C vendor/openhuman rev-parse HEAD
if ($pin -ne '036b13e79e4e555ae249f6245966f384d15f35ba') { throw 'Unexpected OpenHuman commit.' }
if (Test-Path 'scripts/apply_upstream_patches.py') {
    python scripts/apply_upstream_patches.py
    if ($LASTEXITCODE -ne 0) { throw 'Upstream patches failed.' }
}
$rustTarget = if ($Abi -eq 'arm64-v8a') { 'aarch64-linux-android' } else { 'x86_64-linux-android' }
$flutterTarget = if ($Abi -eq 'arm64-v8a') { 'android-arm64' } else { 'android-x64' }
rustup target add $rustTarget
if ($LASTEXITCODE -ne 0) { throw 'Rust target installation failed.' }
$env:CARGO_BUILD_JOBS = '2'
$env:RUSTFLAGS = '-C link-arg=-Wl,-z,max-page-size=16384'
cargo ndk --platform 26 -t $Abi -o android/app/src/main/jniLibs build --locked --release -p arc_openhuman_bridge
if ($LASTEXITCODE -ne 0) { throw 'Rust Android build failed.' }
flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Dart analysis failed.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
flutter build apk --release --flavor qa --target-platform $flutterTarget
if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
