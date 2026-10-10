# Third-party notices and corresponding source

## OpenHuman and the AW native bridge

The embedded runtime comes from https://github.com/tinyhumansai/openhuman at
commit `036b13e79e4e555ae249f6245966f384d15f35ba`. Its workspace and
`openhuman-embed` declare **GPL-3.0-only**. The AW Rust bridge also declares
GPL-3.0-only. A verbatim copy of the upstream license text is included at
`LICENSES/GPL-3.0-only.txt`; upstream notices remain in the materialized source.

Local modifications for this delivery are identified in `patches/manifest.json`.
The original pinned TinyInference revision is
`abf90568a24b826d49900150b20856ef166df3f8`. The patches disable automatic
redirects in the OpenAI-compatible transport and bound raw response bodies
before JSON/SSE assembly. These are local AW changes dated 2026-10-10; they are
not represented as upstream-approved fixes.

An additional local integration patch changes the two optional TinyBus paths
in TinyHosts `94098349c8d75269438e8903f9042148b1ab4752` to the TinyBus checkout
already used by OpenHuman. It resolves lockfile package identity ambiguity;
it does not change the TinyBus implementation or enable a hosting capability.

Two Android portability patches were added on 2026-10-10. TinyTools at
`bd60b9b52f1998b4483b9cf107a72d3338e672f8` uses an Android executable-access
probe only when real and effective user/group IDs match, while preserving
the existing behavior on other Unix targets. OpenHuman at the pinned commit
reports real Android target triples and disables the desktop binary updater
on Android before network, staging or scheduling work. These patches do not
give AW's agent shell, installation or self-modification capabilities.

When conveying a linked APK, provide the complete corresponding source for
that exact delivery, including AW changes, Android configuration, build scripts,
locks, pinned upstream/submodule source, local patches and their notices. A link
to the old AW main branch is not the source of a newer unpushed binary.

This notice records provenance and distribution requirements; it does not
purport to relicense an independent Fluuix/ZonaFranca service consumed by API.
No private backend source is included in this project.

## Other dependencies

Flutter, Dart packages, Rust crates and native libraries retain their respective
licenses. The Dart and Cargo lockfiles identify the resolved dependency graph.
Preserve the license files in the corresponding-source archive and the Flutter
license registry. Do not infer that the OpenHuman license replaces every
third-party license or that a lockfile alone contains their complete source.

Official license text: https://www.gnu.org/licenses/gpl-3.0.en.html
