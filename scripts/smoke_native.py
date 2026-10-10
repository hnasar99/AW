#!/usr/bin/env python3
"""Smoke: biblioteca HOST y OpenHuman reales, inferencia HTTP local sintética.

No prueba Android, un proveedor/modelo real, Arc, wallet ni producción.
Usa ctypes, Python estándar y una clave canario sintética. Cada respuesta C
se libera mediante su ABI. El tool call inválido debe fallar antes del RPC.

  python scripts/smoke_native.py --report /tmp/aw-smoke/report.json
  python scripts/smoke_native.py --include-timeout --report /tmp/aw-smoke/full.json

Compile primero: cargo build -p arc_openhuman_bridge.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import platform
import secrets
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Callable


REPO = Path(__file__).resolve().parents[1]
MODEL = "fixture-model"
TOOLS = {"arc_network_status", "arc_balance"}
HTTP_CAP = 2 * 1024 * 1024
CASE_IDS = [
    "lifecycle_json", "sse_turn", "host_tool_validation", "cancel_and_recover",
    "redirect_refused", "json_size_limit", "error_size_limit",
    "sse_without_event_size_limit", "credential_redaction", "turn_timeout_120s",
    "final_cleanup",
]
SCOPE = {
    "runtime": "biblioteca host real, OpenHuman real y ABI C real",
    "inference": "fixture HTTP local sintético; no hay inferencia de un modelo real",
    "android_verified": False,
    "real_provider_verified": False,
    "arc_network_verified": False,
    "wallet_or_transaction_verified": False,
    "production_certification": False,
}


class SmokeFailure(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SmokeFailure(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")
    temporary.replace(path)


class Native:
    def __init__(self, path: Path):
        self.library = ctypes.CDLL(str(path))
        arguments = {
            "status": [], "cancel": [], "reset": [],
            "init": [ctypes.c_char_p] * 4,
            "turn": [ctypes.c_char_p] * 2,
        }
        for name, types in arguments.items():
            function = getattr(self.library, "arc_openhuman_" + name)
            function.argtypes = types
            # c_char_p would lose the allocation address, preventing correct free.
            function.restype = ctypes.c_void_p
        self.library.arc_openhuman_string_free.argtypes = [ctypes.c_void_p]
        self.library.arc_openhuman_string_free.restype = None

    def call(self, name: str, *args: str) -> dict[str, Any]:
        require(all("\0" not in value for value in args), "NUL in fixture argument")
        pointer = getattr(self.library, "arc_openhuman_" + name)(
            *(value.encode("utf-8") for value in args)
        )
        require(bool(pointer), name + " returned a null response")
        try:
            result = json.loads(ctypes.string_at(pointer).decode("utf-8"))
        finally:
            self.library.arc_openhuman_string_free(pointer)
        require(isinstance(result, dict), name + " did not return a JSON object")
        return result


class Operation:
    def __init__(self, function: Callable[[], dict[str, Any]]):
        self.result: dict[str, Any] | None = None
        self.error: BaseException | None = None
        self.started = time.monotonic()

        def run() -> None:
            try:
                self.result = function()
            except BaseException as error:
                self.error = error

        self.thread = threading.Thread(target=run, daemon=True)
        self.thread.start()

    def wait(self, seconds: float) -> dict[str, Any]:
        self.thread.join(seconds)
        require(not self.thread.is_alive(), f"Native call still active after {seconds:g} s wait")
        if self.error is not None:
            raise self.error
        require(self.result is not None, "Native call returned no result")
        return self.result


class Scenario:
    def __init__(self, mode: str):
        self.mode = mode
        self.seen = threading.Event()
        self.release = threading.Event()
        self.lock = threading.Lock()
        self.requests: list[dict[str, Any]] = []
        self.redirect_hits = 0

    def record(self, path: str, body: dict[str, Any], authenticated: bool) -> None:
        tool_names = sorted(
            item.get("function", {}).get("name", "")
            for item in body.get("tools", []) if isinstance(item, dict)
        )
        messages = body.get("messages", [])
        with self.lock:
            self.requests.append({
                "path": path,
                "model": body.get("model"),
                "stream_requested": body.get("stream"),
                "max_tokens_requested": body.get("max_tokens"),
                "max_completion_tokens_requested": body.get("max_completion_tokens"),
                "tool_names": tool_names,
                "authorization_matches_synthetic_key": authenticated,
                "message_roles": [item.get("role") for item in messages],
                "tool_results": [item.get("content") for item in messages
                                 if item.get("role") == "tool"],
            })
        self.seen.set()


class Fixture:
    def __init__(self, key: str):
        self.key = key
        self.scenario = Scenario("json")
        fixture = self

        class Handler(BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"

            def log_message(self, *_args: Any) -> None:
                pass

            def send_bytes(self, status: int, body: bytes,
                           content_type: str = "application/json") -> None:
                self.send_response(status)
                self.send_header("Content-Type", content_type)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Connection", "close")
                self.end_headers()
                self.wfile.write(body)
                self.wfile.flush()

            def completion(self, text: str, tool: bool = False) -> dict[str, Any]:
                message: dict[str, Any] = {"role": "assistant", "content": text}
                if tool:
                    message["content"] = None
                    message["tool_calls"] = [{
                        "id": "fixture_invalid_address", "type": "function",
                        "function": {"name": "arc_balance",
                                     "arguments": '{"address":"invalid"}'},
                    }]
                return {
                    "id": "aw-synthetic-completion", "object": "chat.completion",
                    "created": int(time.time()), "model": MODEL,
                    "choices": [{"index": 0, "message": message,
                                 "finish_reason": "tool_calls" if tool else "stop"}],
                    "usage": {"prompt_tokens": 10, "completion_tokens": 5,
                              "total_tokens": 15},
                }

            def do_POST(self) -> None:
                scenario = fixture.scenario
                try:
                    size = int(self.headers.get("Content-Length", "0"))
                    if size > HTTP_CAP:
                        self.send_bytes(413, b'{"error":{"message":"fixture request too large"}}')
                        return
                    body = json.loads(self.rfile.read(size))
                    scenario.record(
                        self.path, body,
                        self.headers.get("Authorization") == "Bearer " + fixture.key,
                    )
                    if self.path == "/redirect-target":
                        with scenario.lock:
                            scenario.redirect_hits += 1
                        self.send_bytes(200, json.dumps(self.completion("REDIRECT_WAS_FOLLOWED")).encode())
                        return
                    if self.path != "/v1/chat/completions":
                        self.send_bytes(400, b'{"error":{"message":"unsupported endpoint; use chat completions"}}')
                        return
                    mode = scenario.mode
                    if mode == "redirect":
                        self.send_response(307)
                        self.send_header("Location", fixture.url + "/redirect-target")
                        self.send_header("Content-Length", "0")
                        self.send_header("Connection", "close")
                        self.end_headers()
                    elif mode in {"stall", "sse_limit"}:
                        self.send_response(200)
                        self.send_header("Content-Type", "text/event-stream")
                        self.send_header("Transfer-Encoding", "chunked")
                        self.send_header("Connection", "close")
                        self.end_headers()
                        if mode == "sse_limit":
                            # No newline/event: progress caps alone cannot stop this.
                            chunk = b"x" * 65536
                            for _ in range(HTTP_CAP // len(chunk) + 1):
                                self.wfile.write(f"{len(chunk):x}\r\n".encode() + chunk + b"\r\n")
                                self.wfile.flush()
                        else:
                            chunk = b": fixture waiting\n\n"
                            self.wfile.write(f"{len(chunk):x}\r\n".encode() + chunk + b"\r\n")
                            self.wfile.flush()
                        scenario.release.wait(180)
                        self.wfile.write(b"0\r\n\r\n")
                    elif mode in {"json_limit", "error_limit"}:
                        # Announce an oversized body and withhold it. A body cap
                        # rejects headers promptly; unbounded .text() must wait.
                        self.send_response(400 if mode == "error_limit" else 200)
                        self.send_header("Content-Type", "application/json")
                        self.send_header("Content-Length", str(HTTP_CAP + 1))
                        self.send_header("Connection", "close")
                        self.end_headers()
                        self.wfile.flush()
                        scenario.release.wait(180)
                    elif mode == "sse":
                        events = []
                        for delta, finish in [({"role": "assistant", "content": "FIXTURE_"}, None),
                                              ({"content": "SSE_OK"}, None), ({}, "stop")]:
                            value = {"id": "aw-synthetic-stream", "object": "chat.completion.chunk",
                                     "created": int(time.time()), "model": MODEL,
                                     "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}
                            events.append("data: " + json.dumps(value) + "\n\n")
                        events.append("data: [DONE]\n\n")
                        self.send_bytes(200, "".join(events).encode(), "text/event-stream")
                    else:
                        tool_results = [item for item in body.get("messages", [])
                                        if item.get("role") == "tool"]
                        tool = mode == "tool" and not tool_results
                        text = {
                            "json": "FIXTURE_JSON_OK",
                            "tool": "FIXTURE_TOOL_ERROR_HANDLED",
                            "key": "FIXTURE_REFLECTED_KEY " + fixture.key,
                        }[mode]
                        self.send_bytes(200, json.dumps(self.completion(text, tool)).encode())
                except (BrokenPipeError, ConnectionResetError, TimeoutError):
                    pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.server.daemon_threads = True
        self.url = f"http://127.0.0.1:{self.server.server_port}"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def begin(self, mode: str) -> Scenario:
        self.scenario.release.set()
        self.scenario = Scenario(mode)
        return self.scenario

    def close(self) -> None:
        self.scenario.release.set()
        self.server.shutdown()
        self.server.server_close()


class Runner:
    def __init__(self, native: Native, fixture: Fixture, cache: str,
                 report: dict[str, Any], destination: Path):
        self.native, self.fixture, self.cache = native, fixture, cache
        self.report, self.destination = report, destination
        self.active: Operation | None = None

    def operation(self, name: str, *args: str, deadline: float = 30) -> dict[str, Any]:
        self.active = Operation(lambda: self.native.call(name, *args))
        result = self.active.wait(deadline)
        self.active = None
        return result

    def initialize(self, mode: str) -> Scenario:
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("busy") is False,
                "Native status failed or previous operation left the runtime busy")
        require(self.operation("reset").get("ok") is True, "Reset failed before scenario")
        scenario = self.fixture.begin(mode)
        result = self.operation("init", self.fixture.url + "/v1", self.fixture.key,
                                MODEL, self.cache, deadline=120)
        require(result.get("ok") is True, "Initialization failed: " + str(result.get("code")))
        require(result.get("model_requested") == MODEL, "Init omitted requested model ID")
        return scenario

    def verify_wire(self, scenario: Scenario) -> list[dict[str, Any]]:
        with scenario.lock:
            requests = list(scenario.requests)
        require(bool(requests), "No actual HTTP request reached the fixture")
        for request in requests:
            require(request["path"] == "/v1/chat/completions", "Unexpected inference path")
            require(request["model"] == MODEL, "Requested model ID was not transmitted")
            require(set(request["tool_names"]) == TOOLS, "Advertised tools differ from the two allowed reads")
            require(request["authorization_matches_synthetic_key"], "Synthetic credential did not reach intended endpoint")
        return requests

    def successful_turn(self, mode: str, marker: str) -> dict[str, Any]:
        scenario = self.initialize(mode)
        result = self.operation("turn", "Synthetic smoke fixture. Return the configured fixture response.", "")
        require(result.get("ok") is True, "Turn failed: " + str(result.get("code")))
        require(marker in result.get("reply", ""), "Expected synthetic response was not returned")
        require(bool(result.get("session_id")), "Turn omitted session identifier")
        require(result.get("mode") == "proposal-only", "Turn did not identify proposal-only mode")
        requests = self.verify_wire(scenario)
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("initialized") is True
                and status.get("busy") is False and status.get("requires_reset") is False,
                "Successful turn left invalid lifecycle state")
        return {"response": result, "requests": requests, "status_after": status}

    def lifecycle(self) -> dict[str, Any]:
        evidence = self.successful_turn("json", "FIXTURE_JSON_OK")
        original = evidence["response"]["session_id"]
        resumed = self.operation("turn", "Continue this synthetic session.", original)
        require(resumed.get("ok") is True, "Current session could not be resumed")
        require(resumed.get("session_id") == original, "Resume changed session identifier")
        reset = self.operation("reset")
        require(reset.get("ok") and reset.get("conversation_cleared"), "Reset did not report cleared conversation")
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("initialized") is False
                and status.get("busy") is False, "Reset retained an active agent or status failed")
        missing = self.operation("turn", "Must fail without initialized agent.", "")
        require(missing.get("code") == "NOT_INITIALIZED", "Turn succeeded after reset")
        evidence.update({"resume_session_matches": True, "reset": reset, "post_reset_turn": missing})
        return evidence

    def tool_guard(self) -> dict[str, Any]:
        evidence = self.successful_turn("tool", "FIXTURE_TOOL_ERROR_HANDLED")
        results = [item for request in evidence["requests"] for item in request["tool_results"]]
        require(bool(results), "Fixture never received the runtime's tool result")
        trace = evidence["response"].get("live_reads", [])
        native_errors = [item for item in trace if item.get("tool") == "arc_balance"
                         and item.get("result", {}).get("ok") is False]
        require(bool(native_errors), "No native arc_balance error trace; inspect framework validation stage")
        require(native_errors[0]["result"].get("code") == "INVALID_ADDRESS", "Unexpected native tool guard result")
        require(not any(item.get("result", {}).get("ok") is True for item in trace), "Invalid-address fixture produced a successful live read")
        evidence["arc_read"] = "invalid address rejected before RPC; no live network value established"
        return evidence

    def interrupted(self, full_timeout: bool = False) -> dict[str, Any]:
        scenario = self.initialize("stall")
        self.active = Operation(lambda: self.native.call("turn", "Wait for synthetic fixture.", ""))
        require(scenario.seen.wait(20), "Stalled fixture was never contacted")
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("busy") is True,
                "Status does not observe active native turn")
        blocked_reset = self.native.call("reset")
        blocked_turn = self.native.call("turn", "Concurrent request must fail.", "")
        require(blocked_reset.get("code") == blocked_turn.get("code") == "BUSY", "Concurrent mutation was not refused")
        timeout = status["turn_timeout_seconds"]
        require(timeout == 120, "Native status does not declare the expected 120 s turn deadline")
        cancellation: dict[str, Any] | None = None
        if full_timeout:
            result = self.active.wait(timeout + 20)
            require(result.get("code") == "TIMEOUT", "Stalled request did not reach native TIMEOUT")
            elapsed = time.monotonic() - self.active.started
            require(timeout - 5 <= elapsed <= timeout + 20, "Observed timeout outside native deadline tolerance")
        else:
            started = time.monotonic()
            cancellation = self.native.call("cancel")
            require(cancellation.get("cancellation_requested") is True, "Cancellation did not target active operation")
            result = self.active.wait(15)
            elapsed = time.monotonic() - started
            require(result.get("code") == "CANCELLED", "Cancelled turn did not return CANCELLED")
        self.active = None
        scenario.release.set()
        after = self.native.call("status")
        require(after.get("ok") is True and after.get("busy") is False
                and after.get("requires_reset") is True,
                "Interrupted turn can be resumed without reset or status failed")
        refused = self.operation("turn", "Must require reset after interruption.", "")
        require(refused.get("code") == "RESET_REQUIRED", "Interrupted history was not blocked")
        requests = self.verify_wire(scenario)
        recovered = self.successful_turn("json", "FIXTURE_JSON_OK")
        return {"native_result": result, "observed_seconds": round(elapsed, 3),
                "cancel": cancellation, "busy_reset": blocked_reset,
                "busy_turn": blocked_turn, "status_after_interruption": after,
                "resume_without_reset": refused, "requests": requests,
                "reset_and_reinitialize_succeeded": recovered["response"]["ok"]}

    def failure_mode(self, mode: str) -> dict[str, Any]:
        scenario = self.initialize(mode)
        started = time.monotonic()
        # OpenHuman turn_policy.rs overrides the harness default: 5 attempts,
        # 3/6/12/24 s backoff with 25% jitter. Allow that bounded policy to end;
        # a 20 s test deadline would cancel valid transport rejection retries.
        result = self.operation("turn", "Read the synthetic response safely.", "", deadline=75)
        elapsed = time.monotonic() - started
        require(result.get("ok") is False and result.get("code") == "AGENT_ERROR", "Expected bounded transport failure was not surfaced as AGENT_ERROR")
        require(scenario.redirect_hits == 0, "Inference redirect was followed")
        requests = self.verify_wire(scenario)
        after = self.native.call("status")
        require(after.get("ok") is True and after.get("busy") is False
                and after.get("requires_reset") is True,
                "Transport failure did not invalidate partial conversation or status failed")
        return {"native_result": result, "observed_seconds": round(elapsed, 3),
                "redirect_target_hits": scenario.redirect_hits, "requests": requests,
                "fixture_mode": mode,
                "declared_body_bytes": HTTP_CAP + 1 if mode in {"json_limit", "error_limit"} else None,
                "sse_payload_bytes_planned": HTTP_CAP + 65536 if mode == "sse_limit" else None,
                "sse_events_emitted": 0 if mode == "sse_limit" else None,
                "retry_policy_note": "OpenHuman allows 5 attempts with 3/6/12/24 s backoff and jitter; the host turn remains capped at 120 s.",
                "fixture_withheld_completion": mode in {"json_limit", "error_limit", "sse_limit"}}

    def key_redaction(self) -> dict[str, Any]:
        evidence = self.successful_turn("key", "FIXTURE_REFLECTED_KEY")
        reply = evidence["response"]["reply"]
        require(self.fixture.key not in reply, "Synthetic credential was returned by bridge")
        require("[redacted credential]" in reply, "Credential reflection was not explicitly redacted")
        return evidence

    def cleanup(self) -> dict[str, Any]:
        reset = self.operation("reset")
        require(reset.get("ok") is True, "Final reset failed: " + str(reset.get("code")))
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("initialized") is False
                and status.get("busy") is False and status.get("requires_reset") is False,
                "Final reset did not leave a clean idle runtime")
        self.report["final_reset"] = reset
        self.report["final_status"] = status
        return {"reset": reset, "status": status}

    def run_case(self, name: str, action: Callable[[], dict[str, Any]]) -> None:
        started = time.monotonic()
        case: dict[str, Any] = {"id": name, "status": "running"}
        self.report["cases"].append(case)
        write_json(self.destination, self.report)
        print("RUN " + name, flush=True)
        try:
            case["evidence"] = action()
            case["status"] = "passed"
        except BaseException as error:
            case["status"] = "failed"
            # Credentials are synthetic, but the evidence still follows redaction.
            case["failure"] = str(error).replace(self.fixture.key, "[synthetic key redacted]")
            scenario = self.fixture.scenario
            with scenario.lock:
                case["diagnostic"] = {"requests": list(scenario.requests),
                                      "redirect_target_hits": scenario.redirect_hits,
                                      "fixture_mode": scenario.mode}
        finally:
            self.fixture.scenario.release.set()
            if self.active and self.active.thread.is_alive():
                self.native.call("cancel")
                self.active.thread.join(15)
                if self.active.thread.is_alive():
                    case["failure"] = str(case.get("failure", "")) + "; native call survived cancel"
                    case["duration_seconds"] = round(time.monotonic() - started, 3)
                    write_json(self.destination, self.report)
                    os._exit(124)
            self.active = None
            case["duration_seconds"] = round(time.monotonic() - started, 3)
            write_json(self.destination, self.report)
            print(case["status"].upper() + " " + name, flush=True)


def worker(args: argparse.Namespace) -> int:
    report: dict[str, Any] = {
        "schema_version": 1,
        "scope": SCOPE,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "binary": {"path": str(args.library), "sha256": sha256(args.library),
                   "bytes": args.library.stat().st_size},
        "harness": {"path": str(Path(__file__).resolve()),
                    "sha256": sha256(Path(__file__))},
        "host": {"system": platform.system(), "machine": platform.machine()},
        "build_provenance": "Binary hash observed; correspondence to source is not inferred by this smoke.",
        "planned_cases": CASE_IDS,
        "selected_cases": args.case,
        "cases": [],
    }
    write_json(args.report, report)
    native = Native(args.library)
    report["initial_status"] = native.call("status")
    fixture = Fixture(args.canary)
    try:
        with tempfile.TemporaryDirectory(prefix="aw-native-smoke-") as cache:
            runner = Runner(native, fixture, cache, report, args.report)
            cases: list[tuple[str, Callable[[], dict[str, Any]]]] = [
                ("lifecycle_json", runner.lifecycle),
                ("sse_turn", lambda: runner.successful_turn("sse", "FIXTURE_SSE_OK")),
                ("host_tool_validation", runner.tool_guard),
                ("cancel_and_recover", runner.interrupted),
                ("redirect_refused", lambda: runner.failure_mode("redirect")),
                ("json_size_limit", lambda: runner.failure_mode("json_limit")),
                ("error_size_limit", lambda: runner.failure_mode("error_limit")),
                ("sse_without_event_size_limit", lambda: runner.failure_mode("sse_limit")),
                ("credential_redaction", runner.key_redaction),
                ("turn_timeout_120s", lambda: runner.interrupted(True)),
            ]
            selected = set(args.case) if args.case else set(CASE_IDS) - {"turn_timeout_120s"}
            if args.include_timeout:
                selected.add("turn_timeout_120s")
            for name, action in cases:
                if name in selected:
                    runner.run_case(name, action)
                else:
                    report["cases"].append({"id": name, "status": "skipped",
                                            "reason": "Not selected for this run."})
            runner.run_case("final_cleanup", runner.cleanup)
    finally:
        fixture.close()
        report["completed_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        write_json(args.report, report)
    return 1 if any(item["status"] == "failed" for item in report["cases"]) else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--library", type=Path, default=REPO / "target/debug/libarc_openhuman_bridge.so")
    parser.add_argument("--report", type=Path, default=REPO / "build/native-smoke/report.json")
    parser.add_argument("--include-timeout", action="store_true", help="Measure the full 120 s native timeout.")
    parser.add_argument("--case", action="append", choices=CASE_IDS,
                        help="Run only selected cases (repeatable); final cleanup always runs.")
    parser.add_argument("--worker", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--canary", default="", help=argparse.SUPPRESS)
    args = parser.parse_args()
    args.library, args.report = args.library.resolve(), args.report.resolve()
    if args.worker:
        return worker(args)
    if not args.library.is_file():
        print("BLOCKED: host library not found: " + str(args.library), file=sys.stderr)
        return 2
    args.report.parent.mkdir(parents=True, exist_ok=True)
    stdout_path = args.report.with_suffix(".stdout.log")
    stderr_path = args.report.with_suffix(".stderr.log")
    harness_path = args.report.with_suffix(".harness.py")
    # Execute a fixed source snapshot so later script edits do not make the
    # report's harness hash describe a different implementation of the test.
    harness_path.write_bytes(Path(__file__).read_bytes())
    canary = "aw-smoke-synthetic-" + secrets.token_hex(16)
    command = [sys.executable, str(harness_path), "--worker",
               "--library", str(args.library), "--report", str(args.report), "--canary", canary]
    if args.include_timeout:
        command.append("--include-timeout")
    for name in args.case or []:
        command.extend(["--case", name])
    environment = dict(os.environ)
    for name in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy"):
        environment.pop(name, None)
    environment["NO_PROXY"] = "127.0.0.1,localhost,::1"
    environment["no_proxy"] = environment["NO_PROXY"]
    # Never reuse a previous successful report after a worker startup failure.
    write_json(args.report, {"schema_version": 1, "scope": SCOPE, "planned_cases": CASE_IDS,
                             "process_status": "starting", "cases": []})
    print("HOST OpenHuman real + inferencia fixture sintética; no prueba Android/proveedor/Arc.", flush=True)
    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        child = subprocess.Popen(command, stdout=stdout, stderr=stderr, env=environment)
        try:
            exit_code = child.wait(timeout=480 if args.include_timeout else 330)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
            exit_code = 124
    report = json.loads(args.report.read_text()) if args.report.is_file() else {"scope": SCOPE, "cases": []}
    occurrences = sum(path.read_bytes().count(canary.encode()) for path in [stdout_path, stderr_path])
    for case in report["cases"]:
        if case["status"] == "running":
            case.update(status="failed", failure="Worker ended before the case completed; exit " + str(exit_code))
    recorded = {case["id"] for case in report["cases"]}
    for name in CASE_IDS:
        if name not in recorded:
            report["cases"].append({"id": name, "status": "skipped",
                                    "reason": "Worker terminated before this case could execute."})
    authenticated = any(request.get("authorization_matches_synthetic_key") is True
                        for case in report["cases"]
                        for request in case.get("evidence", {}).get("requests", []))
    canary_status = "failed" if occurrences else "passed" if authenticated else "skipped"
    report["cases"].append({"id": "native_logs_credential_canary", "status": canary_status,
                            "observed_occurrences": occurrences,
                            "authenticated_fixture_request_evidenced": authenticated,
                            "reason": None if authenticated or occurrences else "No authenticated fixture request was evidenced; empty logs are inconclusive.",
                            "scope": "Only captured stdout/stderr in this synthetic host run; not Android or all possible logs."})
    report["process_exit_code"] = exit_code
    report["logs"] = {"stdout": str(stdout_path), "stderr": str(stderr_path),
                      "stdout_sha256": sha256(stdout_path), "stderr_sha256": sha256(stderr_path)}
    report["summary"] = {state: sum(item["status"] == state for item in report["cases"])
                         for state in ["passed", "failed", "skipped", "running"]}
    report["run_status"] = "passed" if exit_code == 0 and not report["summary"]["failed"] else "failed"
    write_json(args.report, report)
    for case in report["cases"]:
        print(case["status"].upper() + " " + case["id"])
    print("Report: " + str(args.report))
    return 0 if exit_code == 0 and not report["summary"]["failed"] and not report["summary"]["running"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
