#!/usr/bin/env python3
"""Package committed AW sources plus verified, already patched git submodules.

The checksum manifest describes bytes and provenance, not legal completeness or
an authenticated signature. No dependency download or repository write occurs.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import posixpath
import re
import stat
import subprocess
import tarfile
import tempfile
from urllib.parse import urlsplit, urlunsplit

SCHEMA = "aw-corresponding-source/v1"
OPENHUMAN = "036b13e79e4e555ae249f6245966f384d15f35ba"
MANIFEST = "SOURCE_MANIFEST.json"
MANIFEST_HASH = "SOURCE_MANIFEST.sha256"
ARCHIVE_ROOT = "AW-source"
REQUIRED = {
    "Cargo.toml", "Cargo.lock", "pubspec.yaml", "pubspec.lock",
    "rust-toolchain.toml", "scripts/prepare_upstream.sh",
    "scripts/apply_upstream_patches.py", "scripts/package_corresponding_source.py",
    "patches/manifest.json", "LICENSES/GPL-3.0-only.txt",
    "README.md", "docs/SOURCE_DISTRIBUTION.md", "scripts/dependency_sources.py",
    "scripts/build_android_rust.sh", "android/gradlew",
    "android/gradle/wrapper/gradle-wrapper.jar", "android/settings.gradle.kts",
    "android/app/build.gradle.kts", "lib/main.dart", "lib/openhuman_bridge.dart",
    "rust/arc_openhuman_bridge/Cargo.toml", "rust/arc_openhuman_bridge/src/lib.rs",
}
CACHE_PARTS = {".git", "node_modules", ".dart_tool", ".pub-cache", ".gradle", "__pycache__", ".pytest_cache", ".mypy_cache"}
BUILD_ROOTS = {"build", "target", "artifacts", "dist", ".next"}
SECRET_NAMES = {".env", "key.properties", "local.properties", "id_rsa", "id_ed25519", "credentials.json"}


def git(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(repo), *args], stderr=subprocess.PIPE)


def relative(value: str) -> str:
    if not isinstance(value, str) or not value or "\\" in value or ":" in value or "\x00" in value:
        raise ValueError(f"Unsafe source path: {value!r}")
    path = PurePosixPath(value)
    if path.is_absolute() or any(p in {"", ".", ".."} for p in value.split("/")):
        raise ValueError(f"Unsafe source path: {value!r}")
    return value


def excluded(name: str, repository_relative: str | None = None) -> bool:
    parts = PurePosixPath(name).parts
    base = parts[-1]
    local = PurePosixPath(repository_relative or name).parts
    return (
        bool(set(parts) & CACHE_PARTS)
        or bool(local and local[0] in BUILD_ROOTS)
        or base in SECRET_NAMES
        or (base.startswith(".env.") and not base.endswith((".example", ".sample", ".template")))
        or base.endswith((".jks", ".keystore", ".p12", ".pfx", ".pyc", ".hprof", ".apk", ".aab"))
        or base == ".DS_Store"
    )


def symlink_destination(name: str, target: str) -> str:
    if not target or "\\" in target or "\x00" in target or target.startswith("/"):
        raise ValueError(f"Unsafe symlink: {name}")
    destination = posixpath.normpath(posixpath.join(posixpath.dirname(name), target))
    relative(destination)
    return destination


def record_file(path: Path, name: str, mode: str | None = None) -> tuple[dict, str]:
    before = path.lstat()
    sha = hashlib.sha256()
    blob = hashlib.sha1()
    if stat.S_ISLNK(before.st_mode):
        target = os.readlink(path)
        symlink_destination(name, target)
        data = target.encode("utf-8")
        sha.update(data)
        blob.update(f"blob {len(data)}\0".encode() + data)
        result = {"type": "symlink", "target": target, "size": len(data), "mode": "0777"}
    elif stat.S_ISREG(before.st_mode):
        blob.update(f"blob {before.st_size}\0".encode())
        with path.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                sha.update(block)
                blob.update(block)
        result = {"type": "file", "size": before.st_size, "mode": mode or ("0755" if before.st_mode & 0o111 else "0644")}
    else:
        raise ValueError(f"Not a regular source file or symlink: {name}")
    after = path.lstat()
    if (before.st_size, before.st_mtime_ns, before.st_ino, before.st_mode) != (after.st_size, after.st_mtime_ns, after.st_ino, after.st_mode):
        raise RuntimeError(f"Source changed while reading: {name}")
    result["sha256"] = sha.hexdigest()
    return result, blob.hexdigest()


def tree_entries(repo: Path) -> dict[str, tuple[str, str]]:
    entries = {}
    for item in git(repo, "ls-tree", "-r", "-z", "HEAD").split(b"\0"):
        if not item:
            continue
        meta, raw_name = item.split(b"\t", 1)
        mode, _kind, object_id = meta.decode().split()
        name = relative(raw_name.decode("utf-8"))
        if mode not in {"100644", "100755", "120000", "160000"}:
            raise ValueError(f"Unsupported git mode for {name}: {mode}")
        entries[name] = (mode, object_id)
    return entries


def load_patches(root: Path) -> list[dict]:
    patches = json.loads((root / "patches/manifest.json").read_text())
    if not isinstance(patches, list):
        raise ValueError("Patch manifest must be a list.")
    for patch in patches:
        repository = relative(patch["repository"])
        filename = relative(patch["patch"])
        if not (repository == "vendor/openhuman" or repository.startswith("vendor/openhuman/")) or not filename.startswith("patches/"):
            raise ValueError("Unexpected patch scope.")
        if not re.fullmatch(r"[0-9a-f]{40}", patch["upstream_commit"]):
            raise ValueError("Invalid patch revision.")
        if hashlib.sha256((root / filename).read_bytes()).hexdigest() != patch["sha256"]:
            raise ValueError(f"Patch checksum mismatch: {filename}")
    return patches


def expected_patch_files(root: Path, repo: Path, entries: dict, patches: list[dict]) -> dict[str, dict | None]:
    """Recreate only touched files from git blobs and apply approved patches off-tree."""
    if not patches:
        return {}
    touched = set()
    for patch in patches:
        stats = git(repo, "apply", "--numstat", "-z", str(root / patch["patch"]))
        for row in stats.split(b"\0"):
            if not row:
                continue
            fields = row.split(b"\t", 2)
            if len(fields) != 3 or not fields[2] or fields[0] == b"-":
                raise ValueError("Source packaging requires ordinary text patches; rename/binary patch unsupported.")
            touched.add(relative(fields[2].decode("utf-8")))
    expected = {}
    with tempfile.TemporaryDirectory(prefix="aw-verified-patches-") as temporary:
        scratch = Path(temporary)
        for name in sorted(touched):
            if name not in entries:
                continue
            mode, _object_id = entries[name]
            if mode not in {"100644", "100755"}:
                raise ValueError(f"Patched source must be a regular file: {name}")
            destination = scratch / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(git(repo, "show", f"HEAD:{name}"))
            destination.chmod(0o755 if mode == "100755" else 0o644)
        for patch in patches:
            subprocess.run(["git", "apply", "--check", str(root / patch["patch"])], cwd=scratch, check=True, capture_output=True)
            subprocess.run(["git", "apply", str(root / patch["patch"])], cwd=scratch, check=True, capture_output=True)
        for name in touched:
            source = scratch / name
            expected[name] = record_file(source, name)[0] if source.exists() or source.is_symlink() else None
    return expected


def clean_url(repo: Path) -> str | None:
    try:
        raw = git(repo, "remote", "get-url", "origin").decode().strip()
    except subprocess.CalledProcessError:
        return None
    parsed = urlsplit(raw)
    if parsed.scheme in {"http", "https", "ssh", "git"} and parsed.hostname:
        port = f":{parsed.port}" if parsed.port else ""
        return urlunsplit((parsed.scheme, parsed.hostname + port, parsed.path, "", ""))
    if re.fullmatch(r"git@[A-Za-z0-9.-]+:[A-Za-z0-9_./-]+", raw):
        host, path = raw[4:].split(":", 1)
        return f"https://{host}/{path}"
    return None


def collect_repository(root: Path, repo: Path, pin: str | None, patches: list[dict], files: dict, sources: dict, repositories: list, omissions: list) -> None:
    name = repo.relative_to(root).as_posix()
    if not (repo / ".git").exists():
        raise RuntimeError(f"Submodule is not initialized: {name}")
    actual_root = Path(git(repo, "rev-parse", "--show-toplevel").decode().strip()).resolve()
    revision = git(repo, "rev-parse", "HEAD").decode().strip()
    if actual_root != repo or (pin is not None and revision != pin):
        raise RuntimeError(f"Unexpected repository or revision: {name}")
    applicable = [p for p in patches if p["repository"] == name]
    if any(p["upstream_commit"] != revision for p in applicable):
        raise RuntimeError(f"Patch revision does not match {name}")
    entries = tree_entries(repo)
    expected = expected_patch_files(root, repo, entries, applicable)
    # In upstream, ignored files are not automatically trusted source: permit
    # only known build/cache/credential paths or declared patch additions.
    other_options = ["--exclude-standard"] if name == "." else []
    untracked = {p.decode("utf-8") for p in git(repo, "ls-files", "--others", *other_options, "-z").split(b"\0") if p}
    unexpected = [p for p in untracked if p not in expected and not excluded(p)]
    if unexpected:
        raise RuntimeError(f"Unversioned source in {name}; commit root files or declare an upstream patch: {unexpected[:8]}")
    repositories.append({"path": name, "commit": revision, "url": clean_url(repo), "patches": [p["patch"] for p in applicable]})
    for local in sorted(set(entries) | set(expected)):
        combined = local if name == "." else f"{name}/{local}"
        source = repo / local
        mode, object_id = entries.get(local, ("100644", ""))
        if mode == "160000":
            collect_repository(root, source, object_id, patches, files, sources, repositories, omissions)
            continue
        if excluded(combined, local):
            omissions.append({"path": combined, "reason": "excluded build/cache/credential filename"})
            continue
        if local in expected and expected[local] is None:
            if source.exists() or source.is_symlink():
                raise RuntimeError(f"Patch-deleted file remains: {combined}")
            continue
        desired_mode = expected[local]["mode"] if local in expected else ("0755" if mode == "100755" else "0644")
        record, actual_blob = record_file(source, combined, desired_mode)
        if local in expected:
            if record != expected[local]:
                raise RuntimeError(f"Source differs from approved patches: {combined}")
        elif actual_blob != object_id:
            # Honor an explicit upstream text/eol=crlf checkout rule without
            # running arbitrary git clean filters or accepting other changes.
            eol = git(repo, "check-attr", "eol", "--", local).decode().strip()
            normalized = source.read_bytes().replace(b"\r\n", b"\n") if eol.endswith(": eol: crlf") and record["type"] == "file" else None
            normalized_blob = hashlib.sha1(f"blob {len(normalized)}\0".encode() + normalized).hexdigest() if normalized is not None else None
            if normalized_blob != object_id:
                raise RuntimeError(f"Unapproved source modification: {combined}")
        files[combined] = record
        sources[combined] = source


def collect_checkout(root: Path, only_upstream: bool = False) -> tuple[dict, dict]:
    patches = load_patches(root)
    files, sources, repositories, omissions = {}, {}, [], []
    if only_upstream:
        collect_repository(root, root / "vendor/openhuman", OPENHUMAN, patches, files, sources, repositories, omissions)
        return {"repositories": repositories, "files": files, "excluded": omissions}, sources
    if not (root / ".git").exists():
        raise RuntimeError("Packaging requires the original git checkout; use --verify for an extracted archive.")
    if subprocess.run(["git", "-C", str(root), "diff", "--quiet", "--ignore-submodules=dirty", "HEAD"]).returncode:
        raise RuntimeError("Commit the final AW source, locks and scripts before packaging.")
    collect_repository(root, root, None, patches, files, sources, repositories, omissions)
    pins = {r["path"]: r["commit"] for r in repositories}
    if pins.get("vendor/openhuman") != OPENHUMAN:
        raise RuntimeError("The committed AW tree must pin the expected OpenHuman gitlink.")
    missing = REQUIRED - files.keys()
    if missing:
        raise RuntimeError(f"Required source files are not committed/included: {sorted(missing)}")
    if MANIFEST in files or MANIFEST_HASH in files:
        raise RuntimeError("Generated source manifests must not already be tracked.")
    manifest = {
        "schema": SCHEMA, "archive_root": ARCHIVE_ROOT,
        "source_commit": pins["."], "openhuman_commit": OPENHUMAN,
        "source_date_epoch": int(git(root, "show", "-s", "--format=%ct", "HEAD").decode()),
        "repositories": repositories, "patches": patches, "files": files,
        "excluded": omissions,
        "dependency_sources": {"included": False, "missing": ["Cargo registry sources", "Dart hosted/SDK package sources", "Gradle/Maven sources", "Flutter engine/Dart runtime and Android toolchain sources"]},
        "legal_completeness_asserted": False,
    }
    return manifest, sources


def verify_archive(root: Path) -> dict:
    root = root.resolve()
    if (root / ".git").exists():
        raise RuntimeError("Archive verification cannot replace the git checkout verification path.")
    raw = (root / MANIFEST).read_bytes()
    wanted = (root / MANIFEST_HASH).read_text().strip()
    if wanted != f"{hashlib.sha256(raw).hexdigest()}  {MANIFEST}":
        raise RuntimeError("Source manifest checksum mismatch.")
    data = json.loads(raw)
    if data.get("schema") != SCHEMA or data.get("archive_root") != ARCHIVE_ROOT or data.get("openhuman_commit") != OPENHUMAN:
        raise ValueError("Unsupported source manifest or OpenHuman revision.")
    files = data["files"]
    if not isinstance(files, dict) or not REQUIRED.issubset(files):
        raise ValueError("Source manifest omits required build inputs.")
    repositories = data["repositories"]
    pins = {r["path"]: r["commit"] for r in repositories}
    if pins.get("vendor/openhuman") != OPENHUMAN or pins.get(".") != data["source_commit"]:
        raise ValueError("Repository revisions disagree with the manifest.")
    for repo, pin in pins.items():
        if repo != ".":
            relative(repo)
            if not repo.startswith("vendor/openhuman"):
                raise ValueError("Unexpected upstream repository path.")
        if not re.fullmatch(r"[0-9a-f]{40}", pin):
            raise ValueError("Invalid source revision.")
    for name, expected in files.items():
        relative(name)
        if ".git" in PurePosixPath(name).parts:
            raise ValueError("Git metadata cannot be part of an archive manifest.")
        if expected.get("type") not in {"file", "symlink"} or expected.get("mode") not in {"0644", "0755", "0777"}:
            raise ValueError(f"Invalid source record: {name}")
        path = root / name
        for parent in path.parents:
            if parent == root:
                break
            if parent.is_symlink():
                raise ValueError(f"Source path traverses a symlink: {name}")
        current, _blob = record_file(path, name, expected["mode"] if os.name == "nt" else None)
        if current != expected:
            raise RuntimeError(f"Source checksum/type/size mismatch: {name}")
        if expected["type"] == "symlink":
            destination = symlink_destination(name, expected["target"])
            if destination not in files and not any(n.startswith(destination + "/") for n in files):
                raise ValueError(f"Symlink target is absent from source archive: {name}")
    if load_patches(root) != data["patches"]:
        raise ValueError("Approved patch manifest differs from the source manifest.")
    for patch in data["patches"]:
        if pins.get(patch["repository"]) != patch["upstream_commit"]:
            raise ValueError("Patch is associated with the wrong source revision.")
    # All upstream files must be accounted for, including new files from patches.
    observed = set()
    upstream = root / "vendor/openhuman"
    for directory, dirs, names in os.walk(upstream, followlinks=False):
        for entry in list(dirs):
            p = Path(directory) / entry
            if entry == ".git":
                raise ValueError("Git metadata cannot be part of an extracted upstream tree.")
            if p.is_symlink():
                names.append(entry)
                dirs.remove(entry)
        for entry in names:
            observed.add((Path(directory) / entry).relative_to(root).as_posix())
    expected_upstream = {n for n in files if n.startswith("vendor/openhuman/")}
    if observed != expected_upstream:
        raise RuntimeError(f"Unexpected/missing upstream files: extra={sorted(observed - expected_upstream)[:8]}, missing={sorted(expected_upstream - observed)[:8]}")
    return {"verified": True, "files": len(files), "repositories": len(repositories), "source_commit": data["source_commit"], "manifest_sha256": hashlib.sha256(raw).hexdigest()}


class CheckedReader:
    def __init__(self, stream):
        self.stream = stream
        self.sha = hashlib.sha256()

    def read(self, size=-1):
        block = self.stream.read(size)
        self.sha.update(block)
        return block


def write_archive(output: Path, manifest: dict, sources: dict) -> dict:
    if output.exists():
        raise FileExistsError(f"Output already exists: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    epoch = manifest["source_date_epoch"]
    raw = (json.dumps(manifest, indent=2, sort_keys=True, ensure_ascii=False) + "\n").encode()
    manifest_hash = hashlib.sha256(raw).hexdigest()
    generated = {MANIFEST: raw, MANIFEST_HASH: f"{manifest_hash}  {MANIFEST}\n".encode()}
    partial = output.with_name(output.name + ".partial")
    try:
        with partial.open("xb") as target, gzip.GzipFile(filename="", mode="wb", fileobj=target, mtime=epoch) as compressed, tarfile.open(fileobj=compressed, mode="w|", format=tarfile.PAX_FORMAT) as tar:
            for name in sorted(set(sources) | set(generated)):
                info = tarfile.TarInfo(f"{ARCHIVE_ROOT}/{name}")
                info.mtime, info.uid, info.gid, info.uname, info.gname = epoch, 0, 0, "", ""
                if name in generated:
                    info.mode, info.size = 0o644, len(generated[name])
                    tar.addfile(info, io.BytesIO(generated[name]))
                    continue
                record = manifest["files"][name]
                source_value = sources[name]
                if isinstance(source_value, bytes):
                    current = {"type": "file", "size": len(source_value), "mode": "0644", "sha256": hashlib.sha256(source_value).hexdigest()}
                else:
                    current, _blob = record_file(source_value, name, record["mode"])
                if current != record:
                    raise RuntimeError(f"Source changed after inventory: {name}")
                info.mode = int(record["mode"], 8)
                if record["type"] == "symlink":
                    info.type, info.linkname = tarfile.SYMTYPE, record["target"]
                    tar.addfile(info)
                else:
                    info.size = record["size"]
                    with (io.BytesIO(source_value) if isinstance(source_value, bytes) else source_value.open("rb")) as source:
                        reader = CheckedReader(source)
                        tar.addfile(info, reader)
                        if reader.sha.hexdigest() != record["sha256"]:
                            raise RuntimeError(f"Source changed while archiving: {name}")
        partial.rename(output)
    except BaseException:
        partial.unlink(missing_ok=True)
        raise
    digest = record_file(output, output.name)[0]["sha256"]
    output.with_name(output.name + ".sha256").write_text(f"{digest}  {output.name}\n")
    return {"archive": str(output), "sha256": digest, "manifest_sha256": manifest_hash, "files": len(sources), "repositories": len(manifest["repositories"]), "dependency_sources": manifest["dependency_sources"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--output", type=Path)
    action.add_argument("--check", action="store_true", help="Validate the committed checkout without writing an archive.")
    action.add_argument("--check-upstream", action="store_true", help="Verify upstream against git plus patches before the AW commit.")
    action.add_argument("--verify", type=Path, metavar="EXTRACTED_ROOT")
    parser.add_argument("--include-dependency-sources", action="store_true")
    parser.add_argument("--allow-missing-dependency-sources", action="store_true")
    args = parser.parse_args()
    if args.allow_missing_dependency_sources and not args.include_dependency_sources:
        parser.error("--allow-missing-dependency-sources requires --include-dependency-sources.")
    if args.verify and args.include_dependency_sources:
        parser.error("--verify checks an existing archive tree; it does not add dependency sources.")
    root = args.root.resolve()
    if args.verify:
        result = verify_archive(args.verify)
    else:
        manifest, sources = collect_checkout(root, args.check_upstream)
        if args.include_dependency_sources:
            if args.check_upstream:
                parser.error("Dependency sources require the committed full checkout.")
            from dependency_sources import include_dependencies
            manifest["dependency_sources"] = include_dependencies(root, manifest["files"], sources, args.allow_missing_dependency_sources)
        if args.output:
            output = args.output.resolve()
            if output.is_relative_to(root):
                parser.error("Write the source archive outside the checkout.")
            result = write_archive(output, manifest, sources)
        else:
            result = {"verified": True, "files": len(sources), "repositories": len(manifest["repositories"]), "excluded": manifest["excluded"], "dependency_sources": manifest.get("dependency_sources")}
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(f"Source verification failed: {error}") from error
