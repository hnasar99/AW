#!/usr/bin/env python3
"""Inventory locally available source for locked Cargo and resolved Dart packages.

No fetches, Cargo operations or dependency mutations occur. The package source
snapshot and its per-file hashes do not certify that a Pub cache is unmodified.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import tarfile
import tomllib
from urllib.parse import unquote, urljoin, urlsplit

from package_corresponding_source import excluded, record_file, relative


def add_file(source: Path, destination: str, files: dict, sources: dict, expected_sha: str | None = None) -> None:
    relative(destination)
    if destination in files:
        raise RuntimeError(f"Duplicate dependency source path: {destination}")
    record, _blob = record_file(source, destination)
    if expected_sha is not None and record["sha256"] != expected_sha:
        raise RuntimeError(f"Cargo source checksum mismatch: {destination}")
    files[destination], sources[destination] = record, source


def cargo_sources(root: Path, files: dict, sources: dict) -> dict:
    lock = tomllib.loads((root / "Cargo.lock").read_text())
    home = Path(os.environ.get("CARGO_HOME", str(Path.home() / ".cargo")))
    included, missing, omitted = [], [], []
    required = [p for p in lock["package"] if p.get("source")]
    for package in required:
        name, version = package["name"], package["version"]
        identity = f"{name}@{version}"
        if not package["source"].startswith("registry+"):
            missing.append({"package": identity, "reason": "non-registry source is not materialized by this helper", "source": package["source"]})
            continue
        candidates = sorted((home / "registry/src").glob(f"*/{name}-{version}"))
        selected = None
        for candidate in candidates:
            crate = home / "registry/cache" / candidate.parent.name / f"{name}-{version}.crate"
            if not crate.is_file():
                continue
            if hashlib.sha256(crate.read_bytes()).hexdigest() == package["checksum"]:
                selected = candidate, crate
                break
        if selected is None:
            missing.append({"package": identity, "reason": "no extracted local source with matching Cargo.lock checksum"})
            continue
        directory, crate = selected
        prefix = f"dependency-sources/cargo/{name}-{version}"
        package_omissions = []
        checksums = {"files": {}, "package": package["checksum"]}
        # Registry extraction caches have .cargo-ok, not necessarily the
        # directory-source checksum file. Derive file checksums from the exact
        # cached .crate after verifying its Cargo.lock archive checksum.
        with tarfile.open(crate, "r:gz") as archive:
            for member in archive:
                if member.isdir():
                    continue
                start = f"{name}-{version}/"
                if not member.name.startswith(start) or not member.isfile():
                    raise RuntimeError(f"Unsupported or unsafe crate member: {identity}")
                local = relative(member.name[len(start):])
                if local in checksums["files"]:
                    raise RuntimeError(f"Duplicate crate member: {identity}/{local}")
                content = archive.extractfile(member)
                digest = hashlib.sha256()
                with content:
                    for block in iter(lambda: content.read(1024 * 1024), b""):
                        digest.update(block)
                checksums["files"][local] = digest.hexdigest()
                # These exact bytes are members of the checksum-verified
                # published crate. A `build/` directory can contain required
                # build.rs modules (for example openssl-sys), and published
                # test certificates are fixtures, not operator credentials.
                # Do not silently omit such corresponding source inputs.
                if ".git" in Path(local).parts:
                    raise RuntimeError(f"Git metadata inside a published crate: {identity}")
                add_file(directory / local, f"{prefix}/{local}", files, sources, digest.hexdigest())
        checksum_name = f"{prefix}/.cargo-checksum.json"
        checksum_data = (json.dumps(checksums, sort_keys=True) + "\n").encode()
        if checksum_name in files:
            raise RuntimeError(f"Duplicate generated checksum file: {identity}")
        files[checksum_name] = {"type": "file", "size": len(checksum_data), "mode": "0644", "sha256": hashlib.sha256(checksum_data).hexdigest()}
        sources[checksum_name] = checksum_data
        included.append({"package": identity, "path": prefix, "archive_sha256": package["checksum"], "cached_archive_checksum_verified": True, "all_included_file_checksums_verified": True})
        if package_omissions:
            omitted.append({"package": identity, "files": package_omissions})
    return {"locked_external_packages": len(required), "included_packages": included, "missing": missing, "excluded_files": omitted}


def pub_lock(path: Path) -> dict[str, dict]:
    """Read the narrow scalar layout emitted by `dart pub` (no YAML execution).

    Reject a new/unsupported layout instead of silently selecting a wrong version.
    The archive builder therefore remains standard-library-only.
    """
    packages, current, section = {}, None, False
    for line in path.read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        if line == "packages:":
            section = True
            continue
        if not line.startswith(" "):
            section = False
            continue
        if not section:
            continue
        heading = re.fullmatch(r"  ([a-zA-Z0-9_]+):", line)
        if heading:
            current = heading[1]
            if current in packages:
                raise ValueError("Duplicate package in pubspec.lock.")
            packages[current] = {}
            continue
        if current is None:
            raise ValueError("Unsupported pubspec.lock layout.")
        value = re.fullmatch(r"(?:    |      )([a-zA-Z0-9_]+):(?: (.*))?", line)
        if value is None:
            raise ValueError(f"Unsupported pubspec.lock scalar layout: {line}")
        key, raw = value[1], value[2]
        if raw is None:
            continue
        if raw.startswith('"'):
            raw = json.loads(raw)
        elif raw.startswith("'") and raw.endswith("'"):
            raw = raw[1:-1].replace("''", "'")
        if key in {"source", "version", "sha256", "url", "name"}:
            packages[current][key] = raw
    if not packages or any(not {"source", "version"}.issubset(p) for p in packages.values()):
        raise ValueError("Incomplete pubspec.lock package records.")
    return packages


def walk_package(directory: Path):
    for base, dirs, names in os.walk(directory, followlinks=False):
        dirs.sort()
        for name in list(dirs):
            source = Path(base) / name
            local = source.relative_to(directory).as_posix()
            if excluded(local):
                dirs.remove(name)
            elif source.is_symlink():
                dirs.remove(name)
                names.append(name)
        for name in sorted(names):
            source = Path(base) / name
            local = source.relative_to(directory).as_posix()
            if not excluded(local):
                yield local, source


def dart_sources(root: Path, files: dict, sources: dict) -> dict:
    lock = pub_lock(root / "pubspec.lock")
    configuration = root / ".dart_tool/package_config.json"
    if not configuration.is_file():
        raise RuntimeError("Run flutter pub get --enforce-lockfile before including resolved Dart source.")
    config = json.loads(configuration.read_text())
    resolved = {p["name"]: p for p in config["packages"]}
    included, missing = [], []
    for name, package in sorted(lock.items()):
        identity = f"{name}@{package['version']}"
        entry = resolved.get(name)
        if not entry:
            missing.append({"package": identity, "reason": "absent from package_config.json"})
            continue
        uri = urlsplit(urljoin(configuration.as_uri(), entry["rootUri"]))
        if uri.scheme != "file" or uri.netloc not in {"", "localhost"}:
            raise RuntimeError(f"Package source is not a local file URI: {name}")
        source = Path(unquote(uri.path))
        if os.name == "nt" and re.match(r"^/[A-Za-z]:", str(source)):
            source = Path(str(source)[1:])
        source = source.resolve()
        if not source.is_dir():
            missing.append({"package": identity, "reason": "resolved package source directory is missing"})
            continue
        source_kind = package["source"]
        if source_kind == "hosted":
            host = urlsplit(package.get("url", "")).hostname
            if not host or source.name != f"{name}-{package['version']}" or source.parent.name != host:
                raise RuntimeError(f"Resolved hosted package does not match locked name/version/host: {identity}")
            wanted_sha = package.get("sha256", "")
            if not re.fullmatch(r"[0-9a-f]{64}", wanted_sha):
                raise RuntimeError(f"Missing hosted archive checksum: {identity}")
            checksum_file = source.parents[2] / "hosted-hashes" / host / f"{source.name}.sha256"
            if not checksum_file.is_file() or checksum_file.read_text().strip() != wanted_sha:
                raise RuntimeError(f"Pub cache archive-checksum metadata disagrees with lock: {identity}")
            prefix = f"dependency-sources/dart/hosted/{host}/{source.name}"
            checksum_destination = f"dependency-sources/dart/hosted-hashes/{host}/{source.name}.sha256"
            add_file(checksum_file, checksum_destination, files, sources)
        elif source_kind == "sdk":
            prefix = f"dependency-sources/dart-sdk/{name}"
        elif source_kind == "path" and source.is_relative_to(root):
            included.append({"package": identity, "kind": "path", "path": source.relative_to(root).as_posix(), "already_in_project_tree": True})
            continue
        else:
            missing.append({"package": identity, "reason": f"unsupported source kind: {source_kind}"})
            continue
        count = 0
        for local, file in walk_package(source):
            add_file(file, f"{prefix}/{local}", files, sources)
            count += 1
        included.append({"package": identity, "kind": source_kind, "path": prefix, "files": count, "locked_archive_sha256": package.get("sha256"), "pub_archive_bytes_reverified": False, "source_state": "actual package_config source, independently hashed per file"})
    return {"locked_packages": len(lock), "included_packages": included, "missing": missing, "package_config_sha256": hashlib.sha256(configuration.read_bytes()).hexdigest()}


def include_dependencies(root: Path, files: dict, sources: dict, allow_missing: bool) -> dict:
    cargo = cargo_sources(root, files, sources)
    dart = dart_sources(root, files, sources)
    missing = len(cargo["missing"]) + len(dart["missing"])
    if (missing or cargo["excluded_files"]) and not allow_missing:
        raise RuntimeError(f"Dependency source coverage is incomplete ({missing} missing packages; {len(cargo['excluded_files'])} Cargo packages have excluded files). Fetch missing locked sources after builds, or explicitly use --allow-missing-dependency-sources for a documented partial snapshot.")
    return {
        "included": True, "all_locked_cargo_and_dart_sources_present": missing == 0 and not cargo["excluded_files"],
        "cargo": cargo, "dart": dart,
        "not_included": ["Gradle/Maven/Android plugin dependency sources", "Complete Flutter engine and Dart runtime source/toolchain", "Android SDK/NDK/JDK/Gradle distributions and their complete source"],
        "offline_android_build_asserted": False, "legal_completeness_asserted": False,
    }
