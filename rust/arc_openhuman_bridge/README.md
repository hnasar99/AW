# OpenHuman native bridge

This crate embeds the actual `openhuman-embed` runtime behind a small C ABI.
It uses the pinned OpenHuman source in `../../vendor/openhuman`, with the
workspace's reviewed patches. The native bridge is GPL-3.0-only.

## Runtime boundary

The runtime and agent loop execute in Rust in the app process. Model inference
uses the user's configured OpenAI-compatible provider. `model_requested` is the
configured identifier, not proof of which model or weights answered. This build
does not enable OpenHuman's voice/local-inference feature or MCP domain.

The reviewed Android compatibility patches are recorded in the root patch
manifest. Android reports its actual target triple, and the upstream desktop
binary updater refuses checks/downloads/staging before network or filesystem
work. Native library updates must ship with the signed Android app package.

Only two host tools are exposed, using `ToolScopeSpec::HostOnly` and
`Access::readonly()`. All other upstream tools are excluded from this agent.

| Tool | Arguments | Live operations |
| --- | --- | --- |
| `arc_network_status` | `{}` | Verify `eth_chainId`, read `eth_blockNumber` |
| `arc_balance` | `{"address":"0x…"}` | Verify chain, read block, `eth_getBalance` at that block |

The tools use only `https://rpc.testnet.arc.io` and require chain ID `5042002`.
They reject unknown fields and malformed addresses. They cannot select other
URLs, arbitrary RPC methods, or sign/send transactions. RPC redirects are
disabled. RPC response bodies are limited to 16 KiB and every whole tool call
has a 20-second deadline. Balances are unsigned 256-bit integers represented as
decimal strings; native USDC uses 18 decimals. The ERC-20 interface's 6-decimal
amounts are a different representation of the same balance.

`live_reads` contains results actually produced by the host tools. Assistant
prose remains model output: the UI must never use that text to assert a live
balance, a confirmed transaction, or authorization to transfer funds. A transfer
proposal requires validation and explicit review in the wallet UI and approval
in the connected external wallet.

## ABI version 1

The C declarations are in `include/arc_openhuman_bridge.h`. A non-null result
is always a newly allocated, NUL-terminated UTF-8 JSON string. Release it exactly
once with `arc_openhuman_string_free`, including error results. Null to the
free function is a no-op. Input pointers must be valid C strings and are borrowed
only during the call. The ABI cannot check whether an arbitrary host pointer is
readable; Dart owns that obligation.

| Function | Inputs | Behavior |
| --- | --- | --- |
| `arc_openhuman_status()` | None | Reports ABI, compiled target, pin, initialization and busy state; no key or network needed |
| `arc_openhuman_init(endpoint,key,model,cache_root)` | C strings | Creates the process runtime and one agent; fails if already initialized |
| `arc_openhuman_turn(prompt,session_id)` | C strings; session may be null/empty | Runs one bounded turn and returns `reply`, `session_id`, `model_requested`, `live_reads` |
| `arc_openhuman_cancel()` | None | Requests cooperative cancellation and immediately reports whether work was active |
| `arc_openhuman_reset()` | None | Requires idle; removes agent/provider route and retained conversation |
| `arc_openhuman_string_free(value)` | A response pointer or null | Releases a response exactly once; null is a no-op |

An error is `{"ok":false,"code":"STABLE_CODE","error":"Safe message"}`.
Provider and RPC error payloads are not forwarded to Dart. Catchable Rust panics
become a static error; memory faults and process aborts cannot be caught.

Call `init`, `turn` and `reset` off the Flutter UI isolate. The native state
lock is not held while inference or network requests run. One operation is
admitted at a time; concurrent work receives `BUSY`. `status` and `cancel` can
run on another isolate during a turn. Cancellation is cooperative and reports
a request, not proof that the remote inference server stopped work or billing.
After cancellation, poll status until `busy` is false, then reset/reinitialize.

Each turn has a 120-second deadline, a 12,000-byte input limit, a 1,024-token
requested model limit, a 128-KiB cumulative progress limit, and a 32-KiB final
reply limit. The provider may ignore the requested token limit; the host checks
its own byte limits as data is observed. The reviewed TinyInference transport
patch disables inference redirects and caps each HTTP response, including SSE
bytes before event parsing, at 2 MiB. The upstream agent policy can retry a
failed model call up to four times, with 3/6/12/24-second delays and jitter.
Some local transport rejections are classified as retryable, so a rejected
redirect or oversized response can take roughly 45 seconds to reach the caller;
the 120-second deadline still bounds the entire turn. The response cap applies
to each attempt, not aggregate provider traffic or process memory.

A failed, cancelled, or interrupted
turn sets `requires_reset` to prevent resuming a partial transcript. At most 32
turns are retained before reset is required, including turns in new sessions.
Only the current returned session ID can be resumed.

## Storage and credentials

Flutter supplies an existing app-private cache directory. The bridge creates a
private temporary directory inside it and uses `tempfile::env::override_temp_dir`
once per process. This avoids assuming `/tmp` exists on Android and avoids
changing process environment variables from a worker thread. The same cache
root must be used on later initialization calls in that process.

OpenHuman is configured with `Workspace::Stateless` and a resettable
`InMemorySessionStores` provider. Conversation transcripts, journals and turn
states are held in memory. Runtime support files can still be written into the
private temporary workspace; stateless does not mean zero filesystem activity.
Android may leave app-cache files after a process kill. The base runtime remains
alive after reset because upstream has process-wide globals; the removed agent
and its old store handles are dropped before the next agent is created.

The API key enters the agent through an ephemeral provider route, which upstream
excludes from serialized config. The bridge's retained copy is zeroized on drop,
but upstream and Dart use additional ordinary string copies. Reset removes the
provider route and retained conversation; it is not a guarantee of forensic or
cryptographic erasure from all process memory. Deleting the persisted credential
from secure storage is a separate Flutter responsibility.

## Verification and delivery limits

From the repository root, after preparing the pinned submodules and patches:

```sh
cargo check --locked -p arc_openhuman_bridge -j 2
cargo test --locked -p arc_openhuman_bridge -j 2
```

For Android, set `ANDROID_NDK_HOME` to the pinned NDK directory and run
`bash scripts/build_android_rust.sh arm64-v8a` (or `x86_64`) from the repository
root. The script supplies `max-page-size=16384`; this crate's `build.rs` supplies
`common-page-size=16384` to the final Android link. Both load-segment alignment
and the end of the RELRO range are verified before installation into JNI.
The script also checks the target architecture, all six C exports and the
dynamic dependency list. Only `libarc_openhuman_bridge.so` is installed; the
upstream crates' auxiliary cdylib outputs are not required by this statically
linked Rust dependency graph. A future additional dynamic dependency fails this
gate and requires an explicit packaging review.

Set `ARC_NATIVE_OUTPUT_DIR` to a staging directory to inspect a candidate without
changing the JNI inputs while Gradle packages another build. ELF checks alone
do not establish that the full APK or its runtime behavior supports 16 KiB pages;
the APK needs separate ZIP/ELF inspection and testing on a 16 KiB Android device.

Tests cover the native status ABI and owned strings, argument and authority
validation, redacted errors, cancellation/deadlines, memory store replacement,
typed tool admission, and real HTTP requests against local mock RPC servers.
Mocks verify request shape and failure handling; they do not establish Arc
availability, live balances, real provider credentials, or Android execution.
Android acceptance additionally requires the built `.so` inside the APK, native
status from an installed app, a credentialed provider turn, and testnet wallet
flows. Reports must name which of these were actually executed.

## Reference semantics

- [OpenHuman pinned embedding API](https://github.com/tinyhumansai/openhuman/tree/036b13e79e4e555ae249f6245966f384d15f35ba/crates/openhuman-embed)
- [Arc connection parameters](https://docs.arc.io/arc/references/connect-to-arc)
- [Arc stablecoin-native model and decimal representations](https://docs.arc.io/arc/concepts/stablecoin-native-model)
- [Rust FFI ownership and unwind boundary](https://doc.rust-lang.org/nomicon/ffi.html)
- [Safe tempfile directory override](https://docs.rs/tempfile/3.27.0/tempfile/env/fn.override_temp_dir.html)
- [Android 16 KiB ELF, RELRO, packaging and device checks](https://developer.android.com/guide/practices/page-sizes)
