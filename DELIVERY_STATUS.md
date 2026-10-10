# Delivery status — Arc Wallet + OpenHuman

Implemented in source:
- Flutter Agent panel wired to a C ABI Dart FFI client.
- Rust bridge depends on the real upstream `openhuman-embed` crate pinned to a commit.
- Read-only wallet assistant, OpenAI-compatible inference configuration, persistent OpenHuman workspace, session continuity, secure-storage handling for the API key.
- Agent-generated transfer proposal can only prefill the transaction form; the existing transaction review and external-wallet signature path remains mandatory.
- Android/iOS native build scripts and pinned Rust toolchain.

Not verified in this environment:
- Rust compilation/linking for Android or iOS.
- Flutter dependency resolution, analyzer, widget tests, and device builds.
- Real model inference, Fluuix/ZonaFranca MCP connectivity, WalletConnect pairing, or a confirmed Arc Testnet transaction.

This is an integrated source deliverable, not a claim that a working APK/IPA or on-chain proof has been produced. Do not ship before the target-device build and end-to-end checks pass.
