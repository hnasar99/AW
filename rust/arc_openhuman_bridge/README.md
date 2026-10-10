# OpenHuman native bridge

This crate exposes `arc_openhuman_init`, `arc_openhuman_turn`, and `arc_openhuman_string_free` as C ABI functions for Dart FFI. It pins `openhuman-embed` to an upstream commit and creates one process-wide OpenHuman runtime plus a read-only `arc_wallet_agent`.

The C ABI is synchronous; Dart invokes it in a worker isolate so model inference does not block Flutter's UI isolate. Build and package a native library for each target architecture. See the root README for Android/iOS packaging instructions.

Security boundary: the agent is configured read-only and host-only; no blockchain signing tool is exposed. A transaction proposal must be reviewed and signed by the external wallet.
