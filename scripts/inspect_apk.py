#!/usr/bin/env python3
"""Inspect APK contents, native ABIs, C ABI symbols and 16 KiB ELF alignment.

This checks a binary artifact. It does not assert installation, inference or a
successful transaction; those require the separate device acceptance run.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import zipfile

EXPECTED = {
    "arc_openhuman_init", "arc_openhuman_turn", "arc_openhuman_status",
    "arc_openhuman_init_lab", "arc_openhuman_turn_lab",
    "arc_openhuman_reset", "arc_openhuman_cancel", "arc_openhuman_string_free",
}
PAGE_SIZE = 16384
PT_LOAD = 1
PT_GNU_RELRO = 0x6474E552
BIONIC_RELRO_SOURCE = (
    "https://android.googlesource.com/platform/bionic/+/android16-qpr2-release/"
    "linker/linker_phdr_16kib_compat.cpp"
)
BIONIC_RELRO_BLOB = "23346b74c38f357c98b39e96909a60ebf8c4a9de"
ANDROID_NAMESPACE = "http://schemas.android.com/apk/res/android:"


def _elf_program_headers(data: bytes) -> tuple[int, list[dict[str, int]]]:
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        raise ValueError("Expected a 64-bit little-endian Android ELF library.")
    machine = struct.unpack_from("<H", data, 18)[0]
    offset = struct.unpack_from("<Q", data, 32)[0]
    entry_size, count = struct.unpack_from("<HH", data, 54)
    if entry_size < 56 or offset + entry_size * count > len(data):
        raise ValueError("ELF program headers exceed the file boundary.")
    headers = []
    for index in range(count):
        entry = offset + index * entry_size
        kind, flags, file_offset, address, _, file_size, memory_size, alignment = (
            struct.unpack_from("<IIQQQQQQ", data, entry)
        )
        if kind not in (PT_LOAD, PT_GNU_RELRO):
            continue
        if address + memory_size > (1 << 64) - 1:
            raise ValueError("ELF segment address overflows uint64.")
        if file_size > memory_size or file_offset + file_size > len(data):
            raise ValueError("ELF segment exceeds its file or memory boundary.")
        headers.append({
            "type": kind, "flags": flags, "offset": file_offset,
            "vaddr": address, "filesz": file_size, "memsz": memory_size,
            "end": address + memory_size, "align": alignment,
        })
    if not any(header["type"] == PT_LOAD for header in headers):
        raise ValueError("ELF has no loadable segments.")
    return machine, headers


def elf_load_alignment(data: bytes) -> tuple[int, list[int], list[int]]:
    """Return raw measurements for existing build-script callers, not a verdict."""
    machine, headers = _elf_program_headers(data)
    alignments = [header["align"] for header in headers if header["type"] == PT_LOAD]
    relro_ends = [header["end"] for header in headers if header["type"] == PT_GNU_RELRO]
    return machine, alignments, relro_ends


def _page_end(address: int) -> int:
    return (address + PAGE_SIZE - 1) & -PAGE_SIZE


def elf_16k_layout(data: bytes) -> dict:
    """Check native 16 KiB mappings; never enable Android compatibility mode.

    Bionic phdr_table_get_relro_min_align exempts a RELRO that starts at the
    same address as a LOAD and covers all of its memory. An unaligned end may
    then protect only trailing padding. Also verify that this rounding cannot
    reach another LOAD or exceed the mapped padding. Checking end % 16384
    alone falsely rejects conventional Flutter and DataStore libraries.
    """
    machine, headers = _elf_program_headers(data)
    loads = sorted((h for h in headers if h["type"] == PT_LOAD), key=lambda h: h["vaddr"])
    relros = [h for h in headers if h["type"] == PT_GNU_RELRO]
    errors = []
    for load in loads:
        alignment = load["align"]
        if alignment < PAGE_SIZE or alignment & (alignment - 1):
            errors.append(f"LOAD alignment is not a power of two >= 16 KiB: {alignment}")
        elif load["offset"] % alignment != load["vaddr"] % alignment:
            errors.append(f"LOAD file/address offsets are not congruent: {load['vaddr']}")
    for previous, current in zip(loads, loads[1:]):
        if previous["end"] > current["vaddr"]:
            errors.append("LOAD memory ranges overlap.")

    decisions = []
    for relro in relros:
        start, end = relro["vaddr"], relro["end"]
        protected_start, protected_end = start & -PAGE_SIZE, _page_end(end)
        owner = next((load for load in loads if load["vaddr"] <= start < load["end"]), None)
        decision = {
            "vaddr": start, "memsz": relro["memsz"], "end": end,
            "end_modulo_16384": end % PAGE_SIZE,
            "protected_start": protected_start, "protected_end": protected_end,
            "rule": "aligned_end", "errors": [],
        }
        if owner is None:
            decision["errors"].append("RELRO starts outside a LOAD memory range.")
        else:
            decision["load_vaddr"] = owner["vaddr"]
            decision["load_memsz"] = owner["memsz"]
            full_load = start == owner["vaddr"] and relro["memsz"] >= owner["memsz"]
            if full_load:
                decision["rule"] = "bionic_full_load_with_safe_padding"
            elif end % PAGE_SIZE:
                decision["errors"].append("Partial LOAD RELRO ends inside a 16 KiB page.")
            if start != owner["vaddr"] and start % PAGE_SIZE:
                decision["errors"].append("RELRO starts inside a writable 16 KiB page.")
            if protected_end > _page_end(owner["end"]):
                decision["errors"].append("RELRO exceeds the owning LOAD's mapped padding.")
            for other in loads:
                if other is owner or other["memsz"] == 0:
                    continue
                if max(protected_start, other["vaddr"]) < min(protected_end, other["end"]):
                    decision["errors"].append("Rounded RELRO protection overlaps another LOAD.")
                    break
        errors.extend(decision["errors"])
        decisions.append(decision)
    return {
        "machine": machine,
        "load_alignments": [load["align"] for load in loads],
        "load_segments": loads,
        "relro_end_addresses": [relro["end"] for relro in relros],
        "relro_checks": decisions,
        "relro_source": BIONIC_RELRO_SOURCE,
        "relro_source_blob": BIONIC_RELRO_BLOB,
        "errors": errors,
    }


def manifest_expectations(pubspec: Path, flavor: str) -> dict:
    """Derive release identity from the checked-out source, never build metadata."""
    raw = pubspec.read_bytes()
    matches = re.findall(r"^version:\s*['\"]?([^\s'\"#]+)['\"]?\s*(?:#.*)?$", raw.decode(), re.MULTILINE)
    if len(matches) != 1:
        raise ValueError("pubspec.yaml must contain exactly one explicit version.")
    match = re.fullmatch(r"(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)\+(\d+)", matches[0])
    if not match or int(match[2]) <= 0:
        raise ValueError("pubspec version must include a positive Android build number, e.g. 0.2.0+2.")
    if flavor not in ("qa", "production"):
        raise ValueError("Supported distribution flavors are qa and production.")
    return {
        "package": "io.fluuix.aw.qa" if flavor == "qa" else "io.fluuix.aw",
        "version_code": int(match[2]),
        "version_name": match[1] + ("-qa" if flavor == "qa" else ""),
        "flavor": flavor,
        "pubspec_sha256": hashlib.sha256(raw).hexdigest(),
    }


def _aapt_value(raw: str):
    raw = raw.strip()
    if raw.startswith('"'):
        return json.JSONDecoder().raw_decode(raw)[0]
    if raw in ("true", "false"):
        return raw == "true"
    typed = re.fullmatch(r"\(type 0x([0-9a-fA-F]+)\)(0x[0-9a-fA-F]+)", raw)
    if typed:
        return bool(int(typed[2], 16)) if int(typed[1], 16) == 0x12 else int(typed[2], 16)
    if re.fullmatch(r"(?:0x[0-9a-fA-F]+|[0-9]+)", raw):
        return int(raw, 16 if raw.startswith("0x") else 10)
    return raw


def _aapt_manifest_tree(output: str) -> dict:
    roots, stack = [], []
    for line in output.splitlines():
        element = re.match(r"^(\s*)E:\s+([\w-]+)(?:\s|$)", line)
        if element:
            indentation = len(element[1])
            while stack and indentation <= stack[-1][0]:
                stack.pop()
            node = {"name": element[2], "attributes": {}, "children": []}
            (stack[-1][1]["children"] if stack else roots).append(node)
            stack.append((indentation, node))
            continue
        attribute = re.match(r"^\s*A:\s+([^=(]+?)(?:\([^)]*\))?=(.*)$", line)
        if attribute and stack:
            name = attribute[1].strip().replace(ANDROID_NAMESPACE, "android:")
            stack[-1][1]["attributes"][name] = _aapt_value(attribute[2])
    if len(roots) != 1 or roots[0]["name"] != "manifest":
        raise ValueError("aapt2 did not return one Android manifest tree.")
    return roots[0]


def check_manifest_dump(output: str, expected: dict) -> dict:
    """Inspect the binary manifest's tree, including the metadata's parent."""
    root = _aapt_manifest_tree(output)
    apps = [child for child in root["children"] if child["name"] == "application"]
    observed = {
        "package": root["attributes"].get("package"),
        "version_code": root["attributes"].get("android:versionCode"),
        "version_name": root["attributes"].get("android:versionName"),
    }
    checks = {key: observed[key] == expected[key] for key in observed}
    checks["version_code"] = type(observed["version_code"]) is int and checks["version_code"]
    checks["single_application"] = len(apps) == 1
    launchers = []
    for application in apps:
        for activity in application["children"]:
            if activity["name"] != "activity":
                continue
            filters = [child for child in activity["children"] if child["name"] == "intent-filter"]
            callback = False
            launcher = False
            for intent in filters:
                actions = {child["attributes"].get("android:name") for child in intent["children"] if child["name"] == "action"}
                categories = {child["attributes"].get("android:name") for child in intent["children"] if child["name"] == "category"}
                data = [child["attributes"] for child in intent["children"] if child["name"] == "data"]
                launcher |= "android.intent.action.MAIN" in actions and "android.intent.category.LAUNCHER" in categories
                callback |= (
                    "android.intent.action.VIEW" in actions
                    and {"android.intent.category.DEFAULT", "android.intent.category.BROWSABLE"}.issubset(categories)
                    and any(item.get("android:scheme") == "awallet" and item.get("android:host") == "callback" for item in data)
                )
            if launcher:
                metadata = [child["attributes"] for child in activity["children"] if child["name"] == "meta-data" and child["attributes"].get("android:name") == "flutter_deeplinking_enabled"]
                launchers.append({
                    "name": activity["attributes"].get("android:name"),
                    "callback": callback,
                    "flutter_deeplinking_disabled": len(metadata) == 1 and metadata[0].get("android:value") is False,
                    "launch_mode": activity["attributes"].get("android:launchMode"),
                })
    observed["launcher_activities"] = launchers
    checks["single_launcher_activity"] = len(launchers) == 1
    checks["callback_on_launcher"] = len(launchers) == 1 and launchers[0]["callback"]
    checks["flutter_deeplinking_disabled"] = len(launchers) == 1 and launchers[0]["flutter_deeplinking_disabled"]
    checks["single_top_launch_mode"] = len(launchers) == 1 and launchers[0]["launch_mode"] == 1
    errors = [f"Binary manifest check failed: {key}." for key, passed in checks.items() if not passed]
    return {"status": "failed" if errors else "passed", "expected": expected, "observed": observed, "checks": checks, "errors": errors, "aapt2_dump_sha256": hashlib.sha256(output.encode()).hexdigest()}


def inspect(path: Path, readelf: Path, aapt2: Path | None = None, expected_manifest: dict | None = None) -> dict:
    binary = path.read_bytes()
    report = {
        "file": path.name,
        "size_bytes": len(binary),
        "sha256": hashlib.sha256(binary).hexdigest(),
        "scope": "APK ZIP/native ABI/ELF/FFI checks, plus binary manifest only when aapt2 is supplied; no signature, device or end-to-end acceptance",
        "native_libraries": [],
        "manifest": {"status": "not_requested"},
        "errors": [],
    }
    with zipfile.ZipFile(io.BytesIO(binary)) as archive:
        broken = archive.testzip()
        if broken:
            raise ValueError(f"APK ZIP integrity failed: {broken}")
        names = set(archive.namelist())
        if "AndroidManifest.xml" not in names or "classes.dex" not in names:
            report["errors"].append("Missing Android application manifest or bytecode.")
        abis = sorted({name.split("/")[1] for name in names if name.startswith("lib/") and name.endswith(".so")})
        if not abis:
            report["errors"].append("APK contains no native code.")
        for abi in abis:
            required = {f"lib/{abi}/{name}" for name in ("libflutter.so", "libapp.so", "libarc_openhuman_bridge.so")}
            if not required.issubset(names):
                report["errors"].append(f"An APK ABI is missing Flutter, Dart AOT or OpenHuman: {abi}")
        for name in sorted(n for n in names if n.startswith("lib/") and n.endswith(".so")):
            data = archive.read(name)
            item = {"path": name, "size_bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "errors": []}
            report["native_libraries"].append(item)
            try:
                item.update(elf_16k_layout(data))
            except ValueError as error:
                item["errors"].append(str(error))
                report["errors"].append(f"{name}: {error}")
                continue
            abi = name.split("/")[1]
            if {"arm64-v8a": 183, "x86_64": 62}.get(abi) != item["machine"]:
                item["errors"].append(f"Unexpected ELF machine for {abi}: {item['machine']}")
            if name.rsplit("/", 1)[-1] in {"libtinymcp.so", "libtinyconnectors.so"}:
                item["errors"].append("Legacy auxiliary cargo-ndk product is not part of the approved APK inventory.")
            if name.endswith("libarc_openhuman_bridge.so"):
                with tempfile.TemporaryDirectory() as temp:
                    so = Path(temp) / "bridge.so"
                    so.write_bytes(data)
                    try:
                        output = subprocess.check_output([str(readelf), "--dyn-syms", "--wide", str(so)], text=True)
                        exported = {line.split()[-1] for line in output.splitlines() if " GLOBAL " in line and " UND " not in line}
                        missing = EXPECTED - exported
                        if missing:
                            item["errors"].append(f"Missing required Dart FFI exports: {sorted(missing)}")
                        else:
                            item["verified_exports"] = sorted(EXPECTED)
                        dynamic = subprocess.check_output([str(readelf), "--dynamic", str(so)], text=True)
                        item["dynamic_dependencies"] = dynamic.splitlines()
                        item["needed"] = sorted(set(re.findall(r"\(NEEDED\).*?\[([^\]]+)\]", dynamic)))
                    except (OSError, subprocess.CalledProcessError) as error:
                        item["errors"].append(f"readelf inspection failed: {error}")
            report["errors"].extend(f"{name}: {error}" for error in item["errors"])
        report["abis"] = abis
    if aapt2 is not None:
        command = [str(aapt2), "dump", "xmltree", "--file", "AndroidManifest.xml", str(path)]
        try:
            if expected_manifest is None:
                raise ValueError("Binary manifest verification requires explicit expectations.")
            output = subprocess.check_output(command, text=True, stderr=subprocess.STDOUT)
            report["manifest"] = check_manifest_dump(output, expected_manifest)
            report["manifest"]["command"] = command
            report["errors"].extend(report["manifest"]["errors"])
            if hashlib.sha256(path.read_bytes()).hexdigest() != report["sha256"]:
                report["errors"].append("APK changed while checking its binary manifest.")
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            report["manifest"] = {"status": "failed", "command": command, "errors": [str(error)]}
            report["errors"].append(f"Binary manifest verification failed: {error}")
    report["static_checks"] = "failed" if report["errors"] else "passed"
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--readelf", required=True, type=Path)
    parser.add_argument("--aapt2", type=Path, help="Also verify the actual APK manifest against pubspec and the selected flavor.")
    parser.add_argument("--pubspec", type=Path, default=Path(__file__).resolve().parents[1] / "pubspec.yaml")
    parser.add_argument("--flavor", choices=("qa", "production"), default="qa")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    expected = manifest_expectations(args.pubspec, args.flavor) if args.aapt2 else None
    report = inspect(args.apk, args.readelf, args.aapt2, expected)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: report[key] for key in ("file", "sha256", "abis", "static_checks", "errors")}, indent=2))
    if report["errors"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
