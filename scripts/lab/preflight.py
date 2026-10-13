#!/usr/bin/env python3
"""Read-only AW lab inventory. Network and device probes require explicit flags.

Python standard library only. A successful inventory never certifies inference,
the AW UI, authentication, or a physical laboratory other than this machine.
"""
from __future__ import annotations

import argparse
import csv
import ctypes
import datetime as dt
import hashlib
import io
import ipaddress
import json
import os
from pathlib import Path
import platform
import re
import shutil
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

SCHEMA = "aw.lab.preflight.v1"
MAX_BODY = 256 * 1024
TIMEOUT = 5
TOOLS = ("git", "java", "openssl", "flutter", "dart", "cargo", "rustc", "adb", "ollama")
STATUSES = {"PASS", "FAIL", "BLOCKED", "NOT RUN"}


def case(name, expected, observed, status, environment="this_machine"):
    if status not in STATUSES:
        raise ValueError("Unknown case status")
    return {"case": name, "environment": environment, "expected": expected,
            "observed": observed, "evidence": "inline:observed", "status": status}


def command(args, timeout=TIMEOUT):
    """Fixed argv only; do not emit raw stderr, environment or device serials."""
    env = dict(os.environ)
    for name in ("ADB_SERVER_SOCKET", "ANDROID_ADB_SERVER_PORT", "ANDROID_SERIAL",
                 "JAVA_TOOL_OPTIONS", "JDK_JAVA_OPTIONS", "_JAVA_OPTIONS"):
        env.pop(name, None)
    try:
        result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=timeout, env=env, text=True, errors="replace")
        return result.returncode, result.stdout[:32768]
    except subprocess.TimeoutExpired:
        return 124, ""
    except OSError:
        return 127, ""


def read_text(path):
    try:
        return Path(path).read_text(errors="replace")[:32768]
    except OSError:
        return ""


def positive_int(value):
    try:
        number = int(value)
        return number if 0 < number < 2**63 else None
    except (TypeError, ValueError):
        return None


def meminfo(text):
    return {key: int(value) * 1024 for key, value in
            re.findall(r"^(MemTotal|MemAvailable):\s+(\d+)\s+kB$", text, re.M)}


def hardware():
    data = {"system": platform.system(), "release": platform.release(),
            "architecture": platform.machine(), "python": platform.python_version(),
            "logical_cpus_reported": os.cpu_count(), "logical_cpus_in_affinity": None,
            "physical_memory_bytes": None, "available_memory_bytes": None,
            "container_memory_limit_bytes": None, "container_cpu_quota_cores": None}
    if hasattr(os, "sched_getaffinity"):
        try:
            data["logical_cpus_in_affinity"] = len(os.sched_getaffinity(0))
        except OSError:
            pass
    if data["system"] == "Linux":
        memory = meminfo(read_text("/proc/meminfo"))
        data.update(physical_memory_bytes=memory.get("MemTotal"),
                    available_memory_bytes=memory.get("MemAvailable"))
        for path in ("/sys/fs/cgroup/memory.max", "/sys/fs/cgroup/memory/memory.limit_in_bytes"):
            limit = positive_int(read_text(path).strip())
            if limit and (not data["physical_memory_bytes"] or limit < data["physical_memory_bytes"]):
                data["container_memory_limit_bytes"] = limit
                break
        quota = read_text("/sys/fs/cgroup/cpu.max").split()
        if len(quota) != 2:
            quota = [read_text("/sys/fs/cgroup/cpu/cpu.cfs_quota_us").strip(),
                     read_text("/sys/fs/cgroup/cpu/cpu.cfs_period_us").strip()]
        if all(positive_int(item) for item in quota):
            data["container_cpu_quota_cores"] = int(quota[0]) / int(quota[1])
        for line in read_text("/etc/os-release").splitlines():
            if line.startswith(("ID=", "VERSION_ID=", "PRETTY_NAME=")):
                key, value = line.split("=", 1)
                data.setdefault("linux_distribution", {})[key.lower()] = value.strip('"')[:160]
    elif data["system"] == "Darwin":
        code, text = command(["sysctl", "-n", "hw.memsize"])
        if code == 0:
            data["physical_memory_bytes"] = positive_int(text.strip())
    elif data["system"] == "Windows":
        class MemoryStatus(ctypes.Structure):
            _fields_ = [("length", ctypes.c_ulong), ("load", ctypes.c_ulong)] + [
                (name, ctypes.c_ulonglong) for name in
                ("total", "available", "page_total", "page_available", "virtual_total",
                 "virtual_available", "extended_available")]
        status = MemoryStatus()
        status.length = ctypes.sizeof(status)
        if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
            data["physical_memory_bytes"] = status.total
            data["available_memory_bytes"] = status.available
    data["limits_scope"] = "Visible OS/affinity and standard cgroup paths; not a benchmark or proof that every nested limit was found."
    return data


def gpu_inventory():
    """Opt-in local inspection; zero visible GPUs does not prove the host has none."""
    nvidia = shutil.which("nvidia-smi")
    if nvidia:
        code, text = command([nvidia, "--query-gpu=name,memory.total,driver_version",
                              "--format=csv,noheader,nounits"])
        if code == 0:
            rows = list(csv.reader(io.StringIO(text)))
            if all(len(row) == 3 for row in rows):
                return {"source": "nvidia-smi", "devices": [
                    {"name": row[0].strip()[:160], "memory_mib_reported": positive_int(row[1]),
                     "driver": row[2].strip()[:80]} for row in rows[:32]]}, "PASS"
    if platform.system() == "Linux":
        devices = []
        for card in sorted(Path("/sys/class/drm").glob("card*")):
            if re.fullmatch(r"card\d+", card.name):
                devices.append({"slot": card.name,
                                "pci_vendor_id": read_text(card / "device/vendor").strip()[:16],
                                "pci_device_id": read_text(card / "device/device").strip()[:16],
                                "vram_bytes_reported": positive_int(read_text(card / "device/mem_info_vram_total").strip())})
        return {"source": "Linux DRM sysfs", "devices": devices,
                "scope": "Only devices exposed to this process; accelerator compatibility and usable VRAM are unverified."}, "PASS"
    return {"reason": "No supported local GPU query is available. Obtain GPU/model/VRAM from this OS; no absence claim."}, "BLOCKED"


def tool_inventory():
    # Some version commands initialize SDKs or contact services. Do not run them
    # implicitly: Ollama's server version comes only from the opt-in HTTP probe.
    result = {name: {"present": bool(shutil.which(name)), "version": None,
                     "version_status": "NOT RUN"} for name in TOOLS}
    for name, args, pattern in (
        ("git", ["git", "--version"], r"git version ([\w.+-]+)"),
        ("java", ["java", "-version"], r'version "([^"\n]+)"'),
        ("openssl", ["openssl", "version"], r"((?:OpenSSL|LibreSSL) [\w.+-]+)"),
    ):
        if result[name]["present"]:
            code, text = command(args)
            match = re.search(pattern, text) if code == 0 else None
            result[name].update(version=match.group(1) if match else None,
                                version_status="PASS" if match else "BLOCKED")
    return result


def repository():
    root = Path(__file__).resolve().parents[2]
    data = {"script_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "commit": None, "branch": None, "working_tree_dirty": None}
    if shutil.which("git"):
        for key, args in (("commit", ["rev-parse", "HEAD"]), ("branch", ["branch", "--show-current"]),
                          ("working_tree_dirty", ["status", "--porcelain=v1"])):
            code, text = command(["git", "-C", str(root), *args])
            if code == 0:
                data[key] = bool(text.strip()) if key == "working_tree_dirty" else text.strip()
    return data


def ollama_origin(raw):
    """Inventory uses /api/* on an explicit origin, not AW's /v1 base URL."""
    if not raw or any(char.isspace() or ord(char) < 32 for char in raw) or "\\" in raw or "%" in raw:
        raise ValueError("Use a literal loopback origin with an explicit port.")
    try:
        parsed = urllib.parse.urlsplit(raw)
        address = ipaddress.ip_address(parsed.hostname or "")
        valid = (parsed.scheme in ("http", "https") and address.is_loopback and
                 parsed.port is not None and 1 <= parsed.port <= 65535 and
                 parsed.username is None and parsed.password is None and
                 parsed.path in ("", "/") and not parsed.query and not parsed.fragment)
    except ValueError:
        valid = False
    if not valid:
        raise ValueError("Use http(s)://<literal-loopback>:<port>, without /v1, credentials, query or fragment.")
    return urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, "", "", ""))


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def http_json(url):
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect(),
                                        urllib.request.HTTPSHandler(context=ssl.create_default_context()))
    request = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "AW-Lab-Preflight/1"})
    started = time.monotonic()
    with opener.open(request, timeout=TIMEOUT) as response:
        if response.status != 200:
            raise ValueError("Expected HTTP 200.")
        length = response.headers.get("Content-Length")
        if length is not None and (not length.isdigit() or int(length) > MAX_BODY):
            raise ValueError("Response exceeds the body limit or has invalid length.")
        raw = response.read(MAX_BODY + 1)
        if len(raw) > MAX_BODY:
            raise ValueError("Response exceeds the body limit.")
    # Reject non-JSON numbers and retain no arbitrary response/error fields.
    def invalid_constant(_):
        raise ValueError("Non-finite JSON number.")
    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("Duplicate JSON key.")
            result[key] = value
        return result
    data = json.loads(raw, parse_constant=invalid_constant, object_pairs_hook=unique_keys)
    return data, {"response_sha256": hashlib.sha256(raw).hexdigest(), "response_bytes": len(raw),
                  "elapsed_ms": round((time.monotonic() - started) * 1000, 2)}


def inventory_payload(path, data):
    if not isinstance(data, dict):
        raise ValueError("Expected a JSON object.")
    if path == "/api/version":
        value = data.get("version")
        if not isinstance(value, str) or not re.fullmatch(r"[\w.+-]{1,80}", value):
            raise ValueError("Missing/invalid version.")
        return {"version": value}
    if not isinstance(data.get("models"), list) or len(data["models"]) > 512:
        raise ValueError("Missing/invalid models list.")
    models = []
    for item in data["models"]:
        if not isinstance(item, dict):
            raise ValueError("Invalid model entry.")
        name = item.get("name") or item.get("model")
        if not isinstance(name, str) or not name or len(name) > 256 or any(ord(c) < 32 for c in name):
            raise ValueError("Missing/invalid model name.")
        clean = {"name": name}
        for key in ("size", "size_vram", "context_length"):
            if key in item:
                value = item[key]
                if type(value) is not int or value < 0:
                    raise ValueError("Invalid model size/context field.")
                clean[key] = value
        digest = item.get("digest")
        if isinstance(digest, str) and re.fullmatch(r"(?:sha256:)?[a-fA-F0-9]{64}", digest):
            clean["digest"] = digest
        clean["remote_reference_reported"] = bool(item.get("remote_host") or item.get("remote_model"))
        details = item.get("details", {})
        if isinstance(details, dict):
            clean["details"] = {key: details[key][:120] for key in
                                ("format", "family", "parameter_size", "quantization_level")
                                if isinstance(details.get(key), str)}
        models.append(clean)
    return {"models": models, "local_execution_proven": False}


def probe_ollama(origin):
    checks = []
    for path in ("/api/version", "/api/tags", "/api/ps"):
        observed = {"origin": origin, "method": "GET", "path": path}
        try:
            data, measured = http_json(origin + path)
            observed.update(measured, payload=inventory_payload(path, data))
            status = "PASS"
        except urllib.error.HTTPError as error:
            observed.update(error="HTTP response rejected; body not retained", http_status=error.code)
            status = "FAIL"
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            observed.update(error="Connection/TLS/timeout failure", error_type=type(error).__name__)
            status = "BLOCKED"
        except (ValueError, UnicodeError, RecursionError):
            observed["error"] = "Invalid or oversized inventory response; body not retained"
            status = "FAIL"
        checks.append(case("OLLAMA" + path, "HTTP 200 and bounded inventory JSON", observed, status, "explicit_loopback_service"))
    return checks


def probe_adb(serial):
    adb = shutil.which("adb")
    expected = "Selected authorized device reports Android version, ABI, boot and page size"
    if not adb:
        return case("ANDROID_DEVICE", expected, {"reason": "adb is not available"}, "BLOCKED", "selected_android_device")
    code, state = command([adb, "-s", serial, "get-state"])
    observed = {"selected_serial_sha256": hashlib.sha256(serial.encode()).hexdigest(),
                "get_state_exit": code, "device_ready": code == 0 and state.strip() == "device"}
    if not observed["device_ready"]:
        return case("ANDROID_DEVICE", expected, observed, "BLOCKED", "selected_android_device")
    fields = {"model": ["getprop", "ro.product.model"], "abi": ["getprop", "ro.product.cpu.abi"],
              "android_release": ["getprop", "ro.build.version.release"],
              "api_level": ["getprop", "ro.build.version.sdk"],
              "boot_completed": ["getprop", "sys.boot_completed"], "page_size": ["getconf", "PAGE_SIZE"]}
    complete = True
    for name, args in fields.items():
        code, text = command([adb, "-s", serial, "shell", *args])
        observed[name] = text.strip()[:160] if code == 0 else None
        complete = complete and code == 0 and bool(text.strip())
    code, text = command([adb, "version"])
    match = re.search(r"Android Debug Bridge version ([\w.+-]+)", text) if code == 0 else None
    observed["adb_version"] = match.group(1) if match else None
    code, text = command([adb, "-s", serial, "shell", "cat", "/proc/meminfo"])
    observed["memory_bytes_reported"] = meminfo(text) if code == 0 else None
    observed["scope"] = "Read-only device metadata; no install, AW launch, reverse mapping or inference."
    complete = complete and observed["boot_completed"] == "1" and bool(positive_int(observed["page_size"]))
    return case("ANDROID_DEVICE", expected, observed, "PASS" if complete else "BLOCKED", "selected_android_device")


def collect(args):
    host = hardware()
    checks = [case("HOST_INVENTORY", "Record OS, architecture, CPU and RAM for this machine", host,
                   "PASS" if host["physical_memory_bytes"] and host["logical_cpus_reported"] else "BLOCKED"),
              case("TOOL_INVENTORY", "Record presence and safe version queries without initializing SDKs",
                   tool_inventory(), "PASS")]
    if args.gpu:
        observed, status = gpu_inventory()
        checks.append(case("GPU_INVENTORY", "Inspect locally visible GPU metadata", observed, status))
    else:
        checks.append(case("GPU_INVENTORY", "Inspect locally visible GPU metadata", "Opt in with --gpu", "NOT RUN"))
    if args.ollama_origin:
        checks.extend(probe_ollama(args.ollama_origin))
    else:
        checks.append(case("OLLAMA_INVENTORY", "Probe an operator-selected loopback service",
                           "No endpoint supplied; no network request made", "NOT RUN"))
    checks.append(probe_adb(args.adb_serial) if args.adb_serial else
                  case("ANDROID_DEVICE", "Inspect one selected Android device", "No serial supplied; adb not invoked", "NOT RUN"))
    checks.extend([
        case("AUTH_NEGATIVE", "Demonstrate actual authentication rejection", "No credentials sent. Native Ollama has no authentication; requires a separately verified auth boundary.", "NOT RUN"),
        case("AW_UI_REAL_INFERENCE", "Correlate AW UI request, local model processing and visible reply",
             "Preflight performs no inference and does not launch AW", "NOT RUN"),
    ])
    return {"schema": SCHEMA, "report_id": str(uuid.uuid4()),
            "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "source": repository(), "checks": checks,
            "scope": "Only this executor/host and explicitly selected probes; not evidence about another lab, AW UI, model locality or financial permissions.",
            "network_policy": "No automatic endpoint discovery, environment proxy, redirect, credential, POST, model download or cloud fallback. HTTPS uses Python's default verified trust store, not Rust's.",
            "status_counts": {status: sum(item["status"] == status for item in checks) for status in sorted(STATUSES)}}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="New JSON file; existing files are never overwritten")
    parser.add_argument("--gpu", action="store_true", help="Opt in to local GPU metadata queries")
    parser.add_argument("--ollama-origin", type=ollama_origin, help="Explicit literal loopback origin and port, without /v1")
    parser.add_argument("--adb-serial", help="Explicit already-connected Android device; adb may start its local server")
    args = parser.parse_args(argv)
    if args.adb_serial and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._:\[\]-]{0,255}", args.adb_serial):
        parser.error("Invalid device serial")
    if args.output.exists():
        parser.error("Output exists; choose a new evidence filename")
    if not args.output.parent.is_dir():
        parser.error("Output parent directory must already exist")
    report = collect(args)
    with args.output.open("x", encoding="utf-8") as file:
        json.dump(report, file, indent=2, ensure_ascii=False)
        file.write("\n")
    print(json.dumps({"report_id": report["report_id"], "output": str(args.output),
                      "status_counts": report["status_counts"], "aw_ui_real_inference": "NOT RUN"}, ensure_ascii=False))
    return 1 if report["status_counts"]["FAIL"] else 2 if report["status_counts"]["BLOCKED"] else 0


if __name__ == "__main__":
    sys.exit(main())
