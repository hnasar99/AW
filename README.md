# AW — Arc Wallet + OpenHuman

Flutter wallet prototype for Arc Testnet with an embedded OpenHuman Rust agent bridge.

## Features

- Arc Testnet JSON-RPC network check, native balance and USDC balance reads.
- WalletConnect v2 connection and external-wallet transaction signing for USDC.
- Transaction review, gas estimation, receipt polling, and ArcScan links.
- Dart FFI bridge to the pinned upstream `openhuman-embed` Rust runtime.
- OpenAI-compatible inference endpoint/model configuration; API key stored through OS secure storage.
- Read-only agent that can draft a structured transfer proposal. The proposal only pre-fills the form; the user must separately review and approve in their external wallet.

## Repository layout

- `lib/main.dart` — Flutter UI, Arc RPC, WalletConnect transaction flow, agent panel.
- `lib/openhuman_bridge.dart` — Dart FFI bridge.
- `rust/arc_openhuman_bridge/` — Rust C ABI bridge and OpenHuman runtime integration.
- `scripts/` — native Rust build scripts for Android and iOS.
- `DELIVERY_STATUS.md` — implementation status and unverified items.
- `THIRD_PARTY_NOTICES.md` — OpenHuman license note.

## Build prerequisites

- Flutter 3.24+ / Dart 3.5+
- Rust 1.96.1 (pinned in `rust-toolchain.toml`)
- Android NDK and Android Rust targets for Android builds
- Xcode/iOS SDK for iOS builds
- A WalletConnect/Reown project ID

Generate missing platform scaffolding and fetch dependencies:

```bash
flutter create . --platforms=android,ios
flutter pub get
```

Configure the WalletConnect project ID at build time:

```bash
flutter run --dart-define=WALLETCONNECT_PROJECT_ID=YOUR_PROJECT_ID
```

Build the Rust bridge for Android (requires `cargo-ndk`, installed with `cargo install cargo-ndk`):

```bash
./scripts/build_android_rust.sh
flutter analyze
flutter test
```

For iOS, run `./scripts/build_ios_rust.sh`, then link the generated static library into the Runner target and configure its native search path. Device and simulator builds require their respective Rust targets.

In the OpenHuman panel, configure an authorized HTTPS OpenAI-compatible API root (not the `/chat/completions` path), model ID, and API key. Do not commit API keys or pass them via `--dart-define`.

## Arc Testnet

- Chain ID: `5042002` (`0x4cef52`)
- RPC: https://rpc.testnet.arc.network
- Explorer: https://testnet.arcscan.app
- USDC contract: `0x3600000000000000000000000000000000000000` (6 decimals)
- Faucet: https://faucet.circle.com/

The app does not request or store a seed phrase or private key. A paired wallet must support EVM WalletConnect and Arc Testnet.

## Status and caveats

This repository contains source code, not a verified APK/IPA. No successful Flutter/Rust compilation, device run, real OpenHuman inference, WalletConnect pairing, or on-chain transfer has yet been verified. The Fluuix/ZonaFranca MCP endpoint and authentication details were not provided, so no live MCP server is configured.

The upstream OpenHuman crate declares GPL-3.0-only. Review license obligations for the intended distribution before shipping. See `THIRD_PARTY_NOTICES.md`.
