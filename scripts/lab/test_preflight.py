"""Probe-policy and evidence tests. HTTP servers below are synthetic fixtures."""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import http.server
import json
from pathlib import Path
import ssl
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import preflight


@contextmanager
def server(routes):
    requests = []

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            requests.append({"path": self.path, "authorization": self.headers.get("Authorization")})
            status, headers, body = routes.get(self.path, (404, {}, b"missing"))
            self.send_response(status)
            for name, value in headers.items():
                self.send_header(name, value)
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

        def log_message(self, *_):
            pass

    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    worker = threading.Thread(target=httpd.serve_forever, kwargs={"poll_interval": 0.01}, daemon=True)
    worker.start()
    try:
        yield f"http://127.0.0.1:{httpd.server_port}", requests
    finally:
        httpd.shutdown()
        httpd.server_close()
        worker.join(timeout=2)


def json_route(value):
    return (200, {"Content-Type": "application/json"}, json.dumps(value).encode())


class OriginTests(unittest.TestCase):
    def test_literal_loopback_and_explicit_port_only(self):
        for value in ("http://127.0.0.1:11434", "http://127.0.0.2:11500/", "https://[::1]:443"):
            with self.subTest(value=value):
                self.assertEqual(preflight.ollama_origin(value), value.rstrip("/"))

    def test_remote_hosts_ambiguous_urls_and_credential_fields_are_rejected(self):
        for value in ("http://localhost:11434", "http://127.1:11434", "http://2130706433:11434",
                      "http://192.168.1.1:11434", "https://provider.example:443", "http://127.0.0.1",
                      "http://127.0.0.1:0", "http://127.0.0.1:65536", "http://127.0.0.1:11434/v1",
                      "http://user:secret@127.0.0.1:11434", "http://127.0.0.1:11434/?key=secret",
                      "http://127.0.0.1:11434/#secret", "http://[::1%25lo]:11434", "ftp://127.0.0.1:11434",
                      "http://127.0.0.1:11434/\n", "http://127.0.0.1:11434\\@example.com"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                preflight.ollama_origin(value)


class HttpProbeTests(unittest.TestCase):
    def test_three_inventory_gets_cannot_claim_inference_or_authentication(self):
        model = {"name": "fixture-model:1b", "size": 1234, "digest": "a" * 64,
                 "api_key": "SYNTHETIC_SECRET_NOT_FOR_LOGS", "system": "PRIVATE_PROMPT_FIXTURE"}
        routes = {"/api/version": json_route({"version": "0.0.0-fixture"}),
                  "/api/tags": json_route({"models": [model]}), "/api/ps": json_route({"models": []})}
        with server(routes) as (origin, requests):
            checks = preflight.probe_ollama(origin)
        self.assertEqual([r["path"] for r in requests], list(routes))
        self.assertTrue(all(r["authorization"] is None for r in requests))
        self.assertEqual([c["status"] for c in checks], ["PASS"] * 3)
        self.assertFalse(checks[1]["observed"]["payload"]["local_execution_proven"])
        output = json.dumps(checks)
        self.assertNotIn("SYNTHETIC_SECRET_NOT_FOR_LOGS", output)
        self.assertNotIn("PRIVATE_PROMPT_FIXTURE", output)
        self.assertEqual(checks[2]["observed"]["payload"]["models"], [])

    def test_redirect_is_not_followed_even_on_same_origin(self):
        with server({"/api/version": (302, {"Location": "/must-not-request"}, b""),
                     "/api/tags": json_route({"models": []}),
                     "/api/ps": json_route({"models": []})}) as (origin, requests):
            checks = preflight.probe_ollama(origin)
        self.assertEqual(checks[0]["status"], "FAIL")
        self.assertEqual(checks[0]["observed"]["http_status"], 302)
        self.assertNotIn("/must-not-request", [r["path"] for r in requests])

    def test_declared_and_streamed_oversize_are_rejected(self):
        for headers in ({"Content-Length": str(preflight.MAX_BODY + 1)}, {}):
            with self.subTest(headers=headers):
                with server({"/oversize": (200, headers, b" " * (preflight.MAX_BODY + 1))}) as (origin, _):
                    with self.assertRaisesRegex(ValueError, "body limit"):
                        preflight.http_json(origin + "/oversize")

    def test_unauthorized_error_body_is_not_logged_or_called_auth_pass(self):
        with server({"/api/version": (401, {}, b"PRIVATE_ERROR_FIXTURE")}) as (origin, _):
            checks = preflight.probe_ollama(origin)
        self.assertEqual(checks[0]["status"], "FAIL")
        self.assertNotIn("PRIVATE_ERROR_FIXTURE", json.dumps(checks))

    def test_malformed_duplicate_and_nonfinite_json_are_rejected(self):
        for body in (b"not json", b'{"version":"a","version":"b"}', b'{"version":NaN}', b"[" * 2000):
            with self.subTest(body=body[:30]):
                with server({"/api/version": (200, {}, body)}) as (origin, _):
                    self.assertEqual(preflight.probe_ollama(origin)[0]["status"], "FAIL")

    def test_wrong_inventory_schema_is_not_a_pass(self):
        for payload in ({"models": "not-list"}, {"models": ["not-object"]},
                        {"models": [{"name": "x", "size": -1}]},
                        {"models": [{"name": "x", "size": True}]}):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                preflight.inventory_payload("/api/tags", payload)

    def test_tls_context_remains_verified_and_environment_proxies_are_disabled(self):
        actual_builder = preflight.urllib.request.build_opener
        seen = []

        def checked_builder(*handlers):
            for handler in handlers:
                if isinstance(handler, preflight.urllib.request.ProxyHandler):
                    self.assertEqual(handler.proxies, {})
                if isinstance(handler, preflight.urllib.request.HTTPSHandler):
                    self.assertTrue(handler._context.check_hostname)
                    self.assertEqual(handler._context.verify_mode, ssl.CERT_REQUIRED)
                    seen.append("verified")
            return actual_builder(*handlers)

        with server({"/version": json_route({"version": "fixture"})}) as (origin, _):
            with patch.object(preflight.urllib.request, "build_opener", side_effect=checked_builder):
                preflight.http_json(origin + "/version")
        self.assertEqual(seen, ["verified"])


class InventoryTests(unittest.TestCase):
    def test_default_report_does_not_probe_network_gpu_or_adb(self):
        args = argparse.Namespace(gpu=False, ollama_origin=None, adb_serial=None)
        with patch.object(preflight, "hardware", return_value={"physical_memory_bytes": 1, "logical_cpus_reported": 1}), \
                patch.object(preflight, "tool_inventory", return_value={}), \
                patch.object(preflight, "repository", return_value={}), \
                patch.object(preflight, "probe_ollama") as network, \
                patch.object(preflight, "probe_adb") as adb, \
                patch.object(preflight, "gpu_inventory") as gpu:
            report = preflight.collect(args)
        network.assert_not_called()
        adb.assert_not_called()
        gpu.assert_not_called()
        cases = {c["case"]: c for c in report["checks"]}
        self.assertEqual(cases["AW_UI_REAL_INFERENCE"]["status"], "NOT RUN")
        self.assertEqual(cases["AUTH_NEGATIVE"]["status"], "NOT RUN")
        self.assertTrue(all(c["status"] in preflight.STATUSES for c in report["checks"]))

    def test_missing_adb_is_blocked_and_never_invoked(self):
        with patch.object(preflight.shutil, "which", return_value=None), patch.object(preflight, "command") as run:
            result = preflight.probe_adb("synthetic-device")
        self.assertEqual(result["status"], "BLOCKED")
        run.assert_not_called()

    def test_device_probe_is_selected_read_only_and_serial_is_not_persisted(self):
        commands = []
        values = {"ro.product.model": "Fixture Phone", "ro.product.cpu.abi": "arm64-v8a",
                  "ro.build.version.release": "15", "ro.build.version.sdk": "35", "sys.boot_completed": "1",
                  "PAGE_SIZE": "16384", "/proc/meminfo": "MemTotal: 123 kB\nMemAvailable: 100 kB\n"}

        def run(args):
            commands.append(args)
            if args[-1] == "get-state":
                return 0, "device\n"
            if args[-1] == "version":
                return 0, "Android Debug Bridge version 1.0.41\n"
            return 0, values[args[-1]]

        with patch.object(preflight.shutil, "which", return_value="adb"), patch.object(preflight, "command", side_effect=run):
            result = preflight.probe_adb("PRIVATE_SERIAL_FIXTURE")
        self.assertEqual(result["status"], "PASS")
        self.assertNotIn("PRIVATE_SERIAL_FIXTURE", json.dumps(result))
        self.assertTrue(all(args[1:3] == ["-s", "PRIVATE_SERIAL_FIXTURE"] for args in commands if args[-1] != "version"))
        self.assertTrue(all(not set(args) & {"install", "reverse", "connect", "pull", "push", "am"} for args in commands))

    def test_an_unbooted_device_is_blocked_not_ui_success(self):
        def run(args):
            if args[-1] == "get-state":
                return 0, "device"
            return 0, "0"
        with patch.object(preflight.shutil, "which", return_value="adb"), patch.object(preflight, "command", side_effect=run):
            self.assertEqual(preflight.probe_adb("fixture")["status"], "BLOCKED")

    def test_memory_units_and_unlimited_cgroup_values_are_distinct(self):
        self.assertEqual(preflight.meminfo("MemTotal: 100 kB\nMemAvailable: 50 kB\n"),
                         {"MemTotal": 102400, "MemAvailable": 51200})
        for value in ("max", "-1", "", "9223372036854775808"):
            self.assertIsNone(preflight.positive_int(value))

    def test_existing_evidence_is_preserved_without_running_probes(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "evidence.json"
            output.write_text("existing evidence")
            with patch.object(preflight, "collect") as collect, self.assertRaises(SystemExit):
                preflight.main(["--output", str(output)])
            collect.assert_not_called()
            self.assertEqual(output.read_text(), "existing evidence")


if __name__ == "__main__":
    unittest.main()
