#!/usr/bin/env python3
"""Real host C ABI/OpenHuman, synthetic loopback HTTP. Never a real LLM/UI test.

  python3 scripts/lab/smoke_native_lab.py --library target/debug/libarc_openhuman_bridge.so --report artifacts/lab-native-smoke.json
  python3 scripts/lab/smoke_native_lab.py --include-timeout --report artifacts/lab-native-full.json

The parent snapshots this script and legacy helpers, then starts an isolated
fixture child with proxy/backend credential variables absent. No environment
of an already running Rust process is changed. Select cases with --case.
"""
from __future__ import annotations

import argparse
import ctypes
import importlib.util
import json
import os
from pathlib import Path
import platform
import re
import secrets
import socket
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Snapshots live beside their helper; the repository copy uses scripts/.
HERE = Path(__file__).resolve()
HELPER = HERE.parent / "smoke_native.py"
if not HELPER.is_file():
    HELPER = HERE.parents[1] / "smoke_native.py"
spec = importlib.util.spec_from_file_location("aw_smoke_helpers", HELPER)
if spec is None or spec.loader is None:
    raise RuntimeError("Legacy smoke helpers unavailable")
legacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(legacy)
require, sha256, write_json, Operation = legacy.require, legacy.sha256, legacy.write_json, legacy.Operation

MODEL = "aw-fixture-local-model"
MODE = "lab-text-only"
REQUEST_PATTERN = r"\[AW-LAB-REQUEST-ID: (awlab-[0-9a-f]{32})\]"
ENV_NAMES = ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy",
             "OPENHUMAN_BACKEND_API_KEY", "OPENHUMAN_BACKEND_SESSION_TOKEN")
CORE_CASES = ("endpoint_rejections", "model_rejections", "mode_json", "model_reconfigure", "sse_turn", "rogue_tools",
              "request_id_rejections", "cancel_reset", "mode_fixed_after_reset", "http_401_fixture",
              "wrong_route_fixture", "redirect_refused", "stopped_service", "turn_timeout_120s")
CASE_IDS = (*CORE_CASES, "environment_guards", "final_cleanup", "captured_log_canaries")
SCOPE = {"runtime": "real host library, OpenHuman and owned-JSON C ABI",
         "inference": "synthetic HTTP fixture; no model weights or LLM inference",
         "android_ui": "NOT RUN", "real_ollama_authentication": "NOT RUN",
         "user_lab": "NOT RUN", "real_arc_or_wallet": "NOT RUN",
         "egress_capture": "NOT RUN; empty tool scope and trace are checked, not all process packets"}


class NativeLab(legacy.Native):
    def __init__(self, path):
        super().__init__(path)
        for name, count in (("init_lab", 4), ("turn_lab", 3)):
            function = getattr(self.library, "arc_openhuman_" + name)
            function.argtypes = [ctypes.c_char_p] * count
            function.restype = ctypes.c_void_p


def record_case(name, status="NOT RUN", observed=None):
    return {"case": name, "environment": "host_native_with_synthetic_fixture", "status": status,
            "expected": EXPECTED[name], "observed": observed, "evidence": "inline:observed"}


EXPECTED = {
    "endpoint_rejections": "Noncanonical/non-loopback/wrong-root lab endpoints rejected before fixture traffic",
    "model_rejections": "Routing hints, @ overrides and cloud model IDs rejected before fixture traffic",
    "mode_json": "Init/status tools=[]; correlated JSON turn on exact /v1/chat/completions; no metadata GET",
    "model_reconfigure": "Reset and select another local model; exact new ID and 4096 budget without metadata GET",
    "sse_turn": "SSE assembled by real runtime; correlated final C ABI response with empty live_reads",
    "rogue_tools": "Forbidden Arc and unknown tools denied by runtime scope; no successful read trace",
    "request_id_rejections": "Invalid correlation IDs rejected before HTTP; valid agent remains usable",
    "cancel_reset": "Busy mutations refused; cancellation bounded; reset required and recovery succeeds",
    "mode_fixed_after_reset": "Reset cannot switch a lab process to proposal-only mode",
    "http_401_fixture": "Synthetic HTTP 401 becomes a correlated error; no authentication claim about Ollama",
    "wrong_route_fixture": "Synthetic route 404 becomes a bounded correlated error",
    "redirect_refused": "307 is not followed; retry policy ends in a correlated error",
    "stopped_service": "Non-listening reserved loopback port becomes a bounded correlated connection failure",
    "turn_timeout_120s": "Actual native 120-second turn timeout, then reset/recovery",
    "environment_guards": "Fresh processes reject each nonempty proxy/backend variable before initialization",
    "final_cleanup": "Idle, uninitialized state with cleared conversation, no reset requirement, and zero fixture GETs across all cases and resets",
    "captured_log_canaries": "Synthetic key and prompt canaries absent from captured native stdout/stderr",
}


class Scenario:
    def __init__(self, mode):
        self.mode = mode
        self.requests = []
        self.lock = threading.Lock()
        self.seen = threading.Event()
        self.release = threading.Event()
        self.redirect_hits = 0
        self.expected_model = MODEL


class Fixture:
    def __init__(self, key):
        self.key = key
        self.scenario = Scenario("json")
        self.all_requests = []
        self.lock = threading.Lock()
        fixture = self

        class Handler(BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"

            def log_message(self, *_):
                pass

            def send_bytes(self, status, body, kind="application/json"):
                self.send_response(status)
                self.send_header("Content-Type", kind)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Connection", "close")
                self.end_headers()
                self.wfile.write(body)
                self.wfile.flush()

            def observe(self, method, body):
                messages = body.get("messages", []) if isinstance(body.get("messages", []), list) else []
                ids, outcomes = set(), []
                for message in messages:
                    if not isinstance(message, dict):
                        continue
                    content = message.get("content", "")
                    text = content if isinstance(content, str) else json.dumps(content)
                    if message.get("role") == "user":
                        ids.update(re.findall(REQUEST_PATTERN, text))
                    if message.get("role") == "tool":
                        lower = text.lower()
                        outcomes.append({"tool_call_id": message.get("tool_call_id"),
                                         "denial_reported": any(term in lower for term in
                                                               ("unknown tool", "denied", "not allowed", "outside the host belt")),
                                         "native_invalid_address_reported": "invalid_address" in lower,
                                         "content_bytes": len(text.encode()),
                                         "content_sha256": legacy.hashlib.sha256(text.encode()).hexdigest()})
                tools = body.get("tools", [])
                names = [item.get("function", {}).get("name") for item in tools if isinstance(item, dict)] if isinstance(tools, list) else ["INVALID_TOOLS_SCHEMA"]
                entry = {"method": method, "path": self.path, "model": body.get("model"),
                         "request_ids": sorted(ids), "tool_names": names,
                         "stream": body.get("stream"), "stream_options": body.get("stream_options"),
                         "max_tokens": body.get("max_tokens"), "max_completion_tokens": body.get("max_completion_tokens"),
                         "authorization_matches_synthetic_key": self.headers.get("Authorization") == "Bearer " + fixture.key,
                         "tool_outcomes": outcomes}
                with fixture.lock:
                    fixture.all_requests.append(entry)
                scenario = fixture.scenario
                with scenario.lock:
                    scenario.requests.append(entry)
                    if self.path == "/redirect-target":
                        scenario.redirect_hits += 1
                scenario.seen.set()
                return scenario, outcomes

            def completion(self, marker, tool=None):
                message = {"role": "assistant", "content": marker}
                if tool:
                    message = {"role": "assistant", "content": None,
                               "tool_calls": [{"id": "aw_fixture_forbidden", "type": "function",
                                               "function": {"name": tool, "arguments": '{"address":"invalid-fixture-address"}'}}]}
                return {"id": "aw-lab-synthetic", "object": "chat.completion", "created": int(time.time()),
                        "model": fixture.scenario.expected_model, "choices": [{"index": 0, "message": message,
                                                     "finish_reason": "tool_calls" if tool else "stop"}],
                        "usage": {"prompt_tokens": 20, "completion_tokens": 5, "total_tokens": 25}}

            def do_GET(self):
                self.observe("GET", {})
                try:
                    self.send_bytes(404, b'{"error":{"message":"metadata GET must not occur in this fixture"}}')
                except (BrokenPipeError, ConnectionResetError):
                    pass

            def do_POST(self):
                try:
                    size = int(self.headers.get("Content-Length", "0"))
                    if not 0 < size <= legacy.HTTP_CAP:
                        self.send_bytes(413, b'{"error":{"message":"invalid fixture body size"}}')
                        return
                    body = json.loads(self.rfile.read(size))
                    scenario, outcomes = self.observe("POST", body)
                    if self.path == "/redirect-target":
                        self.send_bytes(200, json.dumps(self.completion("REDIRECT_WAS_FOLLOWED")).encode())
                        return
                    if self.path != "/v1/chat/completions" or scenario.mode == "wrong_route":
                        self.send_bytes(404, b'{"error":{"message":"synthetic route not found"}}')
                        return
                    mode = scenario.mode
                    if mode == "http_401":
                        self.send_bytes(401, b'{"error":{"message":"synthetic credential rejection"}}')
                    elif mode == "redirect":
                        self.send_response(307)
                        self.send_header("Location", fixture.url + "/redirect-target")
                        self.send_header("Content-Length", "0")
                        self.send_header("Connection", "close")
                        self.end_headers()
                    elif mode == "stall":
                        self.send_response(200)
                        self.send_header("Content-Type", "text/event-stream")
                        self.send_header("Transfer-Encoding", "chunked")
                        self.send_header("Connection", "close")
                        self.end_headers()
                        chunk = b": synthetic wait\n\n"
                        self.wfile.write(f"{len(chunk):x}\r\n".encode() + chunk + b"\r\n")
                        self.wfile.flush()
                        scenario.release.wait(160)
                        self.wfile.write(b"0\r\n\r\n")
                    elif mode == "sse":
                        events = []
                        for delta, finish in (({"role": "assistant", "content": "LAB_FIXTURE_"}, None),
                                              ({"content": "SSE_OK"}, None), ({}, "stop")):
                            value = {"id": "aw-lab-synthetic-stream", "object": "chat.completion.chunk",
                                     "created": int(time.time()), "model": MODEL,
                                     "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}
                            events.append("data: " + json.dumps(value) + "\n\n")
                        events.append("data: [DONE]\n\n")
                        self.send_bytes(200, "".join(events).encode(), "text/event-stream")
                    else:
                        tool = None
                        if mode in ("rogue_arc", "rogue_unknown") and not outcomes:
                            tool = "arc_balance" if mode == "rogue_arc" else "aw_fixture_forbidden_tool"
                        marker = "LAB_FIXTURE_ROGUE_HANDLED" if mode.startswith("rogue_") else "LAB_FIXTURE_JSON_OK"
                        self.send_bytes(200, json.dumps(self.completion(marker, tool)).encode())
                except (BrokenPipeError, ConnectionResetError, TimeoutError):
                    pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.server.daemon_threads = True
        self.url = f"http://127.0.0.1:{self.server.server_port}"
        self.thread = threading.Thread(target=self.server.serve_forever, kwargs={"poll_interval": 0.05}, daemon=True)
        self.thread.start()

    def begin(self, mode):
        self.scenario.release.set()
        self.scenario = Scenario(mode)
        return self.scenario

    def close(self):
        self.scenario.release.set()
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)


def safe_native(value):
    # Retain contract fields, never free-form model replies or error prose.
    result = {key: value[key] for key in
              ("ok", "code", "mode", "inference", "tools", "abi_version", "supported_modes", "lab_context_tokens",
               "initialized", "busy", "requires_reset", "request_id", "duration_ms", "model_requested",
               "live_reads", "cancellation_requested", "conversation_cleared", "provider_route_removed",
               "session_storage", "turn_timeout_seconds", "upstream_commit", "target_arch", "target_os") if key in value}
    if "reply" in value:
        reply = value["reply"]
        require(isinstance(reply, str), "Reply must be text")
        result.update(reply_bytes=len(reply.encode()), reply_sha256=legacy.hashlib.sha256(reply.encode()).hexdigest())
    return result


class Runner(legacy.Runner):
    def __init__(self, native, fixture, cache, report, destination, prompt_canary):
        super().__init__(native, fixture, cache, report, destination)
        self.prompt = "Synthetic local fixture " + prompt_canary

    def policy(self, value):
        require(value.get("ok") is True and value.get("abi_version") == 1, "Invalid native status/init")
        require(value.get("mode") == MODE and value.get("inference") == "lab-endpoint" and value.get("tools") == [],
                "Native laboratory policy is not empty-tools loopback mode")
        require(value.get("lab_context_tokens") == 4096, "Lab metadata budget must be explicit 4096")

    def initialize(self, mode, endpoint=None, model=MODEL):
        status = self.native.call("status")
        require(status.get("ok") is True and status.get("busy") is False, "Runtime not idle before case")
        require(set(status.get("supported_modes", [])) == {"proposal-only", MODE}, "Additive lab capability missing")
        require(self.operation("reset").get("ok") is True, "Reset before case failed")
        scenario = self.fixture.begin(mode)
        scenario.expected_model = model
        value = self.operation("init_lab", endpoint or self.fixture.url + "/v1", self.fixture.key,
                               model, self.cache, deadline=120)
        self.policy(value)
        require(value.get("model_requested") == model, "Init omitted exact requested model")
        self.policy(self.native.call("status"))
        require(not scenario.requests, "Initialization contacted HTTP metadata/inference")
        return scenario

    def correlated(self, result, request_id, model=MODEL):
        require(result.get("request_id") == request_id, "Native correlation ID changed or missing")
        require(type(result.get("duration_ms")) is int and result["duration_ms"] >= 0, "Native duration is not an integer")
        if result.get("ok") is True:
            require(result.get("mode") == MODE and result.get("live_reads") == [] and result.get("model_requested") == model,
                    "Successful turn violates mode/read/model contract")

    def verify_wire(self, scenario, request_id, model=MODEL):
        with scenario.lock:
            requests = list(scenario.requests)
        require(bool(requests), "No actual HTTP fixture request observed")
        for request in requests:
            require(request["method"] == "POST" and request["path"] == "/v1/chat/completions", "Unexpected path/method (including metadata GET)")
            require(request["model"] == model and request["tool_names"] == [], "Model or empty tool advertisement changed")
            require(request_id in request["request_ids"], "Actual prompt did not contain the correlation marker")
            require(request["authorization_matches_synthetic_key"], "Synthetic key did not reach selected fixture")
            require(request["stream"] is True and request["stream_options"] == {"include_usage": True}, "Streaming request contract changed")
        return requests

    def successful(self, mode, marker):
        scenario = self.initialize(mode)
        request_id = "awlab-" + secrets.token_hex(16)
        result = self.operation("turn_lab", self.prompt, "", request_id, deadline=60)
        self.correlated(result, request_id)
        require(result.get("ok") is True and marker in result.get("reply", ""), "Synthetic completion not returned")
        require(bool(result.get("session_id")), "Session identifier missing")
        requests = self.verify_wire(scenario, request_id)
        after = self.native.call("status")
        self.policy(after)
        require(not after.get("busy") and not after.get("requires_reset"), "Success left invalid lifecycle state")
        return {"native": safe_native(result), "requests": requests, "status_after": safe_native(after),
                "expected_fixture_marker_returned": True}

    def endpoints(self):
        self.operation("reset")
        scenario = self.fixture.begin("json")
        base = self.fixture.url
        endpoints = [base + "/v1/", base + "/v1/chat/completions", base + "/wrong", base + "/ignored/../v1",
                     base.replace("127.0.0.1", "localhost") + "/v1",
                     base.replace("127.0.0.1", "127.1") + "/v1", "https://example.invalid/v1"]
        results = []
        for endpoint in endpoints:
            result = self.operation("init_lab", endpoint, self.fixture.key, MODEL, self.cache)
            require(result.get("ok") is False and result.get("code") in {"INVALID_LAB_ENDPOINT", "INVALID_ENDPOINT"},
                    "Invalid laboratory endpoint was accepted")
            results.append({"input_kind": "synthetic_invalid_endpoint", "code": result["code"]})
        require(not scenario.requests, "Rejected endpoint test caused fixture traffic")
        return {"rejections": results, "fixture_requests": 0}

    def models(self):
        self.operation("reset")
        scenario = self.fixture.begin("json")
        results = []
        for model in ("hint:fixture-invalid", "fixture@invalid", "fixture-cloud", "CLOUD-fixture"):
            result = self.operation("init_lab", self.fixture.url + "/v1", self.fixture.key, model, self.cache)
            require(result.get("ok") is False and result.get("code") == "INVALID_LAB_MODEL", "Model routing syntax was accepted")
            results.append({"synthetic_model": model, "code": result["code"]})
        require(not scenario.requests, "Rejected model test caused fixture traffic")
        return {"rejections": results, "fixture_requests": 0}

    def request_ids(self):
        scenario = self.initialize("json")
        results = []
        for request_id in ("missing-prefix", "awlab-" + "A" * 32, "awlab-" + "0" * 31):
            result = self.operation("turn_lab", self.prompt, "", request_id)
            require(result.get("ok") is False and result.get("code") == "INVALID_REQUEST_ID", "Malformed request ID accepted")
            results.append(result["code"])
        require(not scenario.requests, "Invalid request ID reached HTTP")
        require(self.native.call("status").get("requires_reset") is False, "Input validation corrupted initialized state")
        return {"codes": results, "fixture_requests": 0}

    def reconfigure(self):
        first = self.successful("json", "LAB_FIXTURE_JSON_OK")
        model = "aw-fixture-second-local-model"
        scenario = self.initialize("json", model=model)
        request_id = "awlab-" + secrets.token_hex(16)
        result = self.operation("turn_lab", self.prompt, "", request_id, deadline=60)
        self.correlated(result, request_id, model)
        require(result.get("ok") is True and "LAB_FIXTURE_JSON_OK" in result.get("reply", ""), "Second local model turn failed")
        requests = self.verify_wire(scenario, request_id, model)
        after = self.native.call("status")
        self.policy(after)
        return {"first_model_turn": first, "second_model_turn": safe_native(result),
                "requests": requests, "status_after": safe_native(after), "metadata_get_requests": 0}

    def rogue(self):
        evidence = []
        for mode in ("rogue_arc", "rogue_unknown"):
            item = self.successful(mode, "LAB_FIXTURE_ROGUE_HANDLED")
            outcomes = [outcome for request in item["requests"] for outcome in request["tool_outcomes"]]
            require(outcomes and all(outcome["denial_reported"] for outcome in outcomes), "No runtime scope denial returned to fixture")
            require(not any(outcome["native_invalid_address_reported"] for outcome in outcomes),
                    "Arc tool was registered and reached its argument validator")
            item["fixture_mode"] = mode
            evidence.append(item)
        return {"subcases": evidence, "scope": "Unknown/scope denial and empty live_reads; malformed Arc address prevents RPC even under an admission regression. No packet-capture claim."}

    def interrupted(self, full_timeout=False):
        scenario = self.initialize("stall")
        request_id = "awlab-" + secrets.token_hex(16)
        self.active = Operation(lambda: self.native.call("turn_lab", self.prompt, "", request_id))
        require(scenario.seen.wait(20), "Stalled fixture was not contacted")
        status = self.native.call("status")
        require(status.get("busy") is True and status.get("turn_timeout_seconds") == 120, "Active turn/status deadline missing")
        busy_reset = self.native.call("reset")
        busy_turn = self.native.call("turn_lab", self.prompt, "", "awlab-" + secrets.token_hex(16))
        require(busy_reset.get("code") == busy_turn.get("code") == "BUSY", "Concurrent mutation accepted")
        cancellation = None
        if full_timeout:
            result = self.active.wait(140)
            elapsed = time.monotonic() - self.active.started
            require(result.get("code") == "TIMEOUT" and 115 <= elapsed <= 140, "Native timeout not observed at 120 seconds")
        else:
            start = time.monotonic()
            cancellation = self.native.call("cancel")
            require(cancellation.get("cancellation_requested") is True, "Cancellation not requested")
            result = self.active.wait(15)
            elapsed = time.monotonic() - start
            require(result.get("code") == "CANCELLED", "Cancellation did not complete")
        self.active = None
        self.correlated(result, request_id)
        scenario.release.set()
        after = self.native.call("status")
        require(after.get("busy") is False and after.get("requires_reset") is True, "Interrupted history remains usable")
        rejected = self.operation("turn_lab", self.prompt, "", "awlab-" + secrets.token_hex(16))
        require(rejected.get("code") == "RESET_REQUIRED", "Turn after interruption did not require reset")
        requests = self.verify_wire(scenario, request_id)
        recovered = self.successful("json", "LAB_FIXTURE_JSON_OK")
        return {"native": safe_native(result), "observed_seconds": round(elapsed, 3), "requests": requests,
                "cancel": safe_native(cancellation) if cancellation else None,
                "busy_reset": safe_native(busy_reset), "busy_turn": safe_native(busy_turn),
                "after_interruption": safe_native(after), "resume_without_reset": safe_native(rejected),
                "recovery": recovered, "server_processing_stop_proven": False}

    def mode_locked(self):
        self.initialize("json")
        legacy_turn = self.operation("turn", self.prompt, "")
        require(legacy_turn.get("code") == "MODE_LOCKED", "Legacy turn entered lab agent")
        reset = self.operation("reset")
        status = self.native.call("status")
        self.policy(status)
        legacy_init = self.operation("init", self.fixture.url + "/v1", self.fixture.key, MODEL, self.cache)
        require(legacy_init.get("code") == "MODE_LOCKED", "Reset permitted mode escalation")
        return {"legacy_turn": safe_native(legacy_turn), "reset": safe_native(reset),
                "status_after": safe_native(status), "legacy_init": safe_native(legacy_init)}

    def transport_failure(self, mode, endpoint=None):
        scenario = self.initialize(mode, endpoint)
        request_id = "awlab-" + secrets.token_hex(16)
        start = time.monotonic()
        result = self.operation("turn_lab", self.prompt, "", request_id, deadline=75)
        elapsed = time.monotonic() - start
        self.correlated(result, request_id)
        require(result.get("ok") is False and result.get("code") == "AGENT_ERROR", "Transport failure not surfaced")
        require(scenario.redirect_hits == 0, "Redirect target contacted")
        requests = [] if endpoint else self.verify_wire(scenario, request_id)
        if not endpoint:
            require(1 <= len(requests) <= 5, "Retry attempt count exceeds known policy")
        after = self.native.call("status")
        require(after.get("busy") is False and after.get("requires_reset") is True, "Failure did not require reset")
        return {"native": safe_native(result), "requests": requests, "observed_seconds": round(elapsed, 3),
                "redirect_target_hits": scenario.redirect_hits, "status_after": safe_native(after),
                "fixture_mode": mode, "real_authentication_test": False,
                "retry_scope": "At most five HTTP attempts, with 3/6/12/24-second backoff and jitter; native turn cap 120 s."}

    def stopped(self):
        # Reserve a local port without listening: no other process can become
        # the supposed stopped server between selecting and testing this port.
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as reserved:
            reserved.bind(("127.0.0.1", 0))
            endpoint = f"http://127.0.0.1:{reserved.getsockname()[1]}/v1"
            result = self.transport_failure("stopped", endpoint)
        result["listener"] = "reserved loopback TCP port, not listening; connection-refusal fixture"
        result["retry_count_observed"] = None
        return result

    def cleanup(self):
        reset = self.operation("reset")
        status = self.native.call("status")
        with self.fixture.lock:
            requests = list(self.fixture.all_requests)
        http_observation = {
            "requests": len(requests),
            "get_requests": sum(request["method"] == "GET" for request in requests),
            "observation_scope": "All requests received by this configured fixture from its startup through the final reset/status observation, including intervening resets; not a global network capture or a claim about later traffic.",
        }
        self.report["fixture_http_summary"] = http_observation
        require(reset.get("ok") is True and status.get("initialized") is False and status.get("busy") is False
                and status.get("requires_reset") is False, "Final cleanup did not leave idle state")
        require(http_observation["get_requests"] == 0,
                f"Observed {http_observation['get_requests']} fixture GET requests across all cases/resets")
        return {"reset": safe_native(reset), "status": safe_native(status), "http_observation": http_observation}

    def run_case(self, name, action):
        item = next(value for value in self.report["cases"] if value["case"] == name)
        item["execution"] = "in_progress"
        write_json(self.destination, self.report)
        print("RUN " + name, flush=True)
        start = time.monotonic()
        try:
            item.update(status="PASS", observed=action())
        except BaseException as error:
            message = str(error).replace(self.fixture.key, "[synthetic key redacted]").replace(self.prompt, "[synthetic prompt redacted]")
            item.update(status="FAIL", observed={"error_type": type(error).__name__, "failure": message,
                                                "requests": list(self.fixture.scenario.requests)})
        finally:
            if self.active and self.active.thread.is_alive():
                self.native.call("cancel")
                self.fixture.scenario.release.set()
                self.active.thread.join(15)
                if self.active.thread.is_alive():
                    item.update(status="FAIL", observed={"failure": "Native call survived cancellation"})
                    write_json(self.destination, self.report)
                    os._exit(124)
            self.active = None
            self.fixture.scenario.release.set()
            item.update(execution="finished", duration_seconds=round(time.monotonic() - start, 3))
            write_json(self.destination, self.report)
            print(item["status"] + " " + name, flush=True)


def child(args):
    report = {"schema": "aw.lab.native-smoke.v1", "scope": SCOPE,
              "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "binary": {"sha256": sha256(args.library), "bytes": args.library.stat().st_size},
              "harness": {"sha256": sha256(HERE), "legacy_helpers_sha256": sha256(HELPER)},
              "host": {"system": platform.system(), "architecture": platform.machine()},
              "build_provenance": "Binary identity observed; source-to-binary correspondence needs the separate build evidence.",
              "cases": [record_case(name) for name in CASE_IDS]}
    write_json(args.report, report)
    try:
        native = NativeLab(args.library)
        report["initial_status"] = safe_native(native.call("status"))
    except (OSError, AttributeError) as error:
        report["cases"] = [record_case(name, "BLOCKED", {"reason": "Host library or additive C ABI unavailable", "error_type": type(error).__name__}) for name in CASE_IDS]
        write_json(args.report, report)
        return 2
    if args.guard_env:
        with tempfile.TemporaryDirectory(prefix="aw-lab-env-guard-") as cache:
            result = native.call("init_lab", "http://127.0.0.1:1/v1", args.canary, MODEL, cache)
        report["guard_observation"] = {"variable_name": args.guard_env, "result": safe_native(result),
                                       "status": "PASS" if result.get("ok") is False and result.get("code") == "LAB_ENVIRONMENT" else "FAIL",
                                       "scope": "Synthetic variable present before native library load; initialization guard only"}
        write_json(args.report, report)
        return 0 if report["guard_observation"]["status"] == "PASS" else 1
    fixture = Fixture(args.canary)
    try:
        with tempfile.TemporaryDirectory(prefix="aw-lab-native-") as cache:
            runner = Runner(native, fixture, cache, report, args.report, args.prompt_canary)
            actions = {"endpoint_rejections": runner.endpoints, "model_rejections": runner.models,
                       "mode_json": lambda: runner.successful("json", "LAB_FIXTURE_JSON_OK"),
                       "model_reconfigure": runner.reconfigure,
                       "sse_turn": lambda: runner.successful("sse", "LAB_FIXTURE_SSE_OK"), "rogue_tools": runner.rogue,
                       "request_id_rejections": runner.request_ids, "cancel_reset": runner.interrupted,
                       "mode_fixed_after_reset": runner.mode_locked,
                       "http_401_fixture": lambda: runner.transport_failure("http_401"),
                       "wrong_route_fixture": lambda: runner.transport_failure("wrong_route"),
                       "redirect_refused": lambda: runner.transport_failure("redirect"), "stopped_service": runner.stopped,
                       "turn_timeout_120s": lambda: runner.interrupted(True)}
            for name in CORE_CASES:
                if name in args.selected:
                    runner.run_case(name, actions[name])
            runner.run_case("final_cleanup", runner.cleanup)
    finally:
        fixture.close()
        report["completed_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        write_json(args.report, report)
    return 1 if any(c["status"] == "FAIL" for c in report["cases"]) else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--library", type=Path, default=HERE.parents[2] / "target/debug/libarc_openhuman_bridge.so")
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--include-timeout", action="store_true")
    parser.add_argument("--case", action="append", choices=CASE_IDS)
    parser.add_argument("--fixture-child", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--guard-env", choices=ENV_NAMES, help=argparse.SUPPRESS)
    parser.add_argument("--canary", default="", help=argparse.SUPPRESS)
    parser.add_argument("--prompt-canary", default="", help=argparse.SUPPRESS)
    args = parser.parse_args()
    args.library, args.report = args.library.resolve(), args.report.resolve()
    args.selected = set(args.case or CASE_IDS) - {"turn_timeout_120s"}
    if args.include_timeout or args.case and "turn_timeout_120s" in args.case:
        args.selected.add("turn_timeout_120s")
    if args.fixture_child:
        return child(args)
    if args.report.exists():
        parser.error("Report already exists; choose a new evidence filename")
    if not args.library.is_file():
        report = {"schema": "aw.lab.native-smoke.v1", "scope": SCOPE,
                  "cases": [record_case(name, "BLOCKED", {"reason": "Compile the host library first"}) for name in CASE_IDS],
                  "run_status": "BLOCKED"}
        write_json(args.report, report)
        print("BLOCKED: host library is unavailable; no native test ran")
        return 2
    sources = args.report.with_suffix(".sources")
    sources.mkdir(parents=True, exist_ok=False)
    snapshot = sources / "smoke_native_lab.py"
    snapshot.write_bytes(HERE.read_bytes())
    (sources / "smoke_native.py").write_bytes(HELPER.read_bytes())
    key = "aw-lab-synthetic-" + secrets.token_hex(16)
    prompt_canary = "aw-lab-prompt-canary-" + secrets.token_hex(16)
    environment = dict(os.environ)
    removed = [name for name in ENV_NAMES if environment.get(name)]
    for name in ENV_NAMES:
        environment.pop(name, None)
    environment.update(PYTHONDONTWRITEBYTECODE="1", NO_PROXY="127.0.0.1,::1", no_proxy="127.0.0.1,::1")
    base_command = [sys.executable, "-B", str(snapshot), "--fixture-child", "--library", str(args.library),
                    "--canary", key, "--prompt-canary", prompt_canary]
    command = [*base_command, "--report", str(args.report)]
    for name in sorted(args.selected):
        command.extend(["--case", name])
    stdout_path, stderr_path = args.report.with_suffix(".stdout.log"), args.report.with_suffix(".stderr.log")
    with stdout_path.open("xb") as stdout, stderr_path.open("xb") as stderr:
        process = subprocess.Popen(command, stdout=stdout, stderr=stderr, env=environment)
        try:
            exit_code = process.wait(timeout=720 if "turn_timeout_120s" in args.selected else 580)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            exit_code = 124
    report = json.loads(args.report.read_text()) if args.report.is_file() else {
        "schema": "aw.lab.native-smoke.v1", "scope": SCOPE, "cases": [record_case(name) for name in CASE_IDS]}
    for item in report["cases"]:
        if item.get("execution") == "in_progress":
            item.update(status="FAIL", observed={"reason": "Fixture child terminated before completion", "exit_code": exit_code})
    log_paths = [stdout_path, stderr_path]
    guard_item = next(item for item in report["cases"] if item["case"] == "environment_guards")
    if "environment_guards" in args.selected and exit_code != 2:
        observations = []
        for index, name in enumerate(ENV_NAMES):
            guard_report = sources / f"environment-guard-{index}.json"
            guard_out, guard_err = sources / f"environment-guard-{index}.stdout.log", sources / f"environment-guard-{index}.stderr.log"
            guard_env = dict(environment)
            guard_env[name] = "http://127.0.0.1:1" if "proxy" in name.lower() else key
            guard_command = [*base_command, "--report", str(guard_report), "--guard-env", name]
            with guard_out.open("xb") as stdout, guard_err.open("xb") as stderr:
                try:
                    result = subprocess.run(guard_command, env=guard_env, stdout=stdout, stderr=stderr, timeout=35)
                    code = result.returncode
                except subprocess.TimeoutExpired:
                    code = 124
            log_paths.extend([guard_out, guard_err])
            data = json.loads(guard_report.read_text()) if guard_report.is_file() else {}
            observation = data.get("guard_observation", {"variable_name": name, "status": "BLOCKED", "exit_code": code})
            observations.append(observation)
        status = "FAIL" if any(item["status"] == "FAIL" for item in observations) else "BLOCKED" if any(item["status"] == "BLOCKED" for item in observations) else "PASS"
        guard_item.update(status=status, observed={"subcases": observations, "environment_mutation_in_live_native_process": False})
    key_hits = prompt_hits = 0
    logs = []
    for path in log_paths:
        raw = path.read_bytes()
        key_hits += raw.count(key.encode())
        prompt_hits += raw.count(prompt_canary.encode())
        clean = raw.replace(key.encode(), b"[synthetic key redacted]").replace(prompt_canary.encode(), b"[synthetic prompt canary redacted]")
        if clean != raw:
            path.write_bytes(clean)
        logs.append({"path": str(path), "sha256": sha256(path), "redactions_applied": clean != raw})
    serialized = json.dumps(report)
    authenticated = '"authorization_matches_synthetic_key": true' in serialized
    item = next(item for item in report["cases"] if item["case"] == "captured_log_canaries")
    item.update(status="FAIL" if key_hits or prompt_hits else "PASS" if authenticated else "NOT RUN",
                observed={"synthetic_key_occurrences": key_hits, "synthetic_prompt_occurrences": prompt_hits,
                          "authenticated_fixture_request_observed": authenticated,
                          "scope": "Only captured stdout/stderr of these host fixture children; no Android/all-logs guarantee"})
    report.update(process_exit_code=exit_code, logs=logs,
                  child_environment={"removed_nonempty_variable_names": removed, "values_recorded": False,
                                     "scope": "Fixture child only; parent and any other Rust process environment left intact"})
    report["summary"] = {state: sum(c["status"] == state for c in report["cases"]) for state in ("PASS", "FAIL", "BLOCKED", "NOT RUN")}
    report["run_status"] = "FAIL" if report["summary"]["FAIL"] or exit_code not in (0, 2) else "BLOCKED" if report["summary"]["BLOCKED"] or exit_code == 2 else "PASS"
    # Canaries are synthetic, but never persist their actual values in evidence.
    report = json.loads(json.dumps(report).replace(key, "[synthetic key redacted]").replace(prompt_canary, "[synthetic prompt canary redacted]"))
    write_json(args.report, report)
    for item in report["cases"]:
        print(item["status"] + " " + item["case"])
    print("Report: " + str(args.report))
    return {"PASS": 0, "FAIL": 1, "BLOCKED": 2}[report["run_status"]]


if __name__ == "__main__":
    raise SystemExit(main())
