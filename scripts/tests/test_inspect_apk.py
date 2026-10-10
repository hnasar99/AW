"""Guard 16 KiB RELRO acceptance against real loader edge cases."""
from __future__ import annotations

from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import inspect_apk as inspector


def header(kind, address, size, *, offset=None, filesz=None, align=16384, flags=6):
    return (kind, flags, address if offset is None else offset, address, 0,
            size if filesz is None else filesz, size, align)


def elf(*headers, machine=183):
    length = max(64 + 56 * len(headers), *(h[2] + h[5] for h in headers))
    data = bytearray(length)
    data[:7] = b"\x7fELF\x02\x01\x01"
    struct.pack_into("<H", data, 18, machine)
    struct.pack_into("<Q", data, 32, 64)
    struct.pack_into("<HH", data, 54, 56, len(headers))
    for index, item in enumerate(headers):
        struct.pack_into("<IIQQQQQQ", data, 64 + index * 56, *item)
    return bytes(data)


def load(address=0x4100, size=0x1800, **kwargs):
    return header(inspector.PT_LOAD, address, size, **kwargs)


def relro(address=0x4100, size=0x1800, **kwargs):
    return header(inspector.PT_GNU_RELRO, address, size, align=1, flags=4, **kwargs)


class RelroLayoutTests(unittest.TestCase):
    def test_entire_load_with_unaligned_end_is_accepted(self):
        result = inspector.elf_16k_layout(elf(load(), relro()))
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["relro_checks"][0]["rule"], "bionic_full_load_with_safe_padding")
        self.assertNotEqual(result["relro_end_addresses"][0] % 16384, 0)

    def test_entire_load_with_padding_and_separate_next_load_is_accepted(self):
        # DataStore 1.1.7 uses RELRO padding beyond its LOAD's logical end.
        result = inspector.elf_16k_layout(elf(load(), relro(size=0x1F00), load(0x9900, 0x100)))
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["relro_checks"][0]["protected_end"], 0x8000)

    def test_unaligned_partial_load_relro_is_rejected(self):
        result = inspector.elf_16k_layout(elf(load(size=0x5000), relro()))
        self.assertIn("Partial LOAD RELRO ends inside a 16 KiB page.", result["errors"])

    def test_aligned_partial_load_relro_is_accepted(self):
        result = inspector.elf_16k_layout(elf(load(size=0x5000), relro(size=0x3F00)))
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["relro_checks"][0]["rule"], "aligned_end")

    def test_full_load_exception_cannot_protect_bytes_of_next_load(self):
        result = inspector.elf_16k_layout(elf(load(), relro(), load(0x6100, 0x100)))
        self.assertIn("Rounded RELRO protection overlaps another LOAD.", result["errors"])

    def test_full_load_exception_cannot_claim_unmapped_padding(self):
        result = inspector.elf_16k_layout(elf(load(), relro(size=0x4F00)))
        self.assertIn("RELRO exceeds the owning LOAD's mapped padding.", result["errors"])

    def test_relro_start_cannot_split_a_writable_page(self):
        result = inspector.elf_16k_layout(elf(load(size=0x5000), relro(0x5000, 0x3000)))
        self.assertIn("RELRO starts inside a writable 16 KiB page.", result["errors"])

    def test_missing_relro_does_not_invent_a_hardening_guarantee(self):
        result = inspector.elf_16k_layout(elf(load()))
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["relro_checks"], [])

    def test_bad_alignment_and_file_mapping_are_rejected(self):
        for data in (elf(load(align=4096)), elf(load(align=24576)), elf(load(offset=0x200))):
            with self.subTest():
                self.assertTrue(inspector.elf_16k_layout(data)["errors"])

    def test_truncated_headers_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "program headers"):
            inspector.elf_16k_layout(elf(load())[:70])

    def test_raw_measurement_api_remains_compatible(self):
        self.assertEqual(inspector.elf_load_alignment(elf(load(), relro())),
                         (183, [16384], [0x5900]))


class ApkInventoryTests(unittest.TestCase):
    def test_bad_library_does_not_hide_later_library_or_abi_failures(self):
        with tempfile.TemporaryDirectory() as directory:
            apk = Path(directory) / "bad.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("AndroidManifest.xml", b"fixture")
                archive.writestr("classes.dex", b"fixture")
                archive.writestr("lib/arm64-v8a/libbad.so", elf(load(align=4096)))
                archive.writestr("lib/arm64-v8a/liblater.so", elf(load(), relro()))
            result = inspector.inspect(apk, Path("unused-readelf"))
            self.assertEqual(result["static_checks"], "failed")
            self.assertEqual(len(result["native_libraries"]), 2)
            self.assertTrue(result["native_libraries"][0]["errors"])
            self.assertEqual(result["native_libraries"][1]["errors"], [])
            self.assertTrue(any("missing Flutter" in error for error in result["errors"]))

    def test_ffi_exports_are_still_required_after_alignment_acceptance(self):
        with tempfile.TemporaryDirectory() as directory:
            apk = Path(directory) / "missing-export.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("AndroidManifest.xml", b"fixture")
                archive.writestr("classes.dex", b"fixture")
                for name in ("libflutter.so", "libapp.so", "libarc_openhuman_bridge.so"):
                    archive.writestr(f"lib/arm64-v8a/{name}", elf(load(), relro()))
            with patch.object(inspector.subprocess, "check_output", return_value=""):
                result = inspector.inspect(apk, Path("mocked-readelf"))
            self.assertEqual(result["static_checks"], "failed")
            self.assertTrue(any("Missing required Dart FFI exports" in error for error in result["errors"]))


# Synthetic aapt2 xmltree output using the real tool's nesting and values.
# It is a parser fixture, not evidence of a newly built or installed APK.
VALID_MANIFEST = '''E: manifest (line=2)
  A: android:versionCode(0x0101021b)=2
  A: android:versionName(0x0101021c)="0.2.0-qa"
  A: package="io.fluuix.aw.qa"
  E: application (line=10)
    E: activity (line=12)
      A: android:name="io.fluuix.arc_wallet_flutter.MainActivity"
      A: android:launchMode=1
      E: meta-data (line=15)
        A: android:name="flutter_deeplinking_enabled"
        A: android:value=false
      E: intent-filter (line=20)
        E: action (line=21)
          A: android:name="android.intent.action.MAIN"
        E: category (line=22)
          A: android:name="android.intent.category.LAUNCHER"
      E: intent-filter (line=25)
        E: action (line=26)
          A: android:name="android.intent.action.VIEW"
        E: category (line=27)
          A: android:name="android.intent.category.DEFAULT"
        E: category (line=28)
          A: android:name="android.intent.category.BROWSABLE"
        E: data (line=29)
          A: android:scheme="awallet"
          A: android:host="callback"
'''
OPTOUT = '''      E: meta-data (line=15)
        A: android:name="flutter_deeplinking_enabled"
        A: android:value=false
'''
EXPECTED_MANIFEST = {"package": "io.fluuix.aw.qa", "version_code": 2, "version_name": "0.2.0-qa"}


class BinaryManifestTests(unittest.TestCase):
    def test_current_identity_callback_and_boolean_in_both_aapt_formats(self):
        full_namespace = VALID_MANIFEST.replace("android:", inspector.ANDROID_NAMESPACE)
        typed_values = VALID_MANIFEST.replace("versionCode(0x0101021b)=2", "versionCode(0x0101021b)=(type 0x10)0x2").replace("value=false", "value=(type 0x12)0x0")
        for output in (VALID_MANIFEST, full_namespace, typed_values):
            with self.subTest():
                result = inspector.check_manifest_dump(output, EXPECTED_MANIFEST)
                self.assertEqual(result["errors"], [])

    def test_old_version_and_missing_optout_are_rejected(self):
        stale = VALID_MANIFEST.replace("versionCode(0x0101021b)=2", "versionCode(0x0101021b)=1").replace('"0.2.0-qa"', '"1.0-qa"').replace(OPTOUT, "")
        result = inspector.check_manifest_dump(stale, EXPECTED_MANIFEST)
        self.assertFalse(result["checks"]["version_code"])
        self.assertFalse(result["checks"]["version_name"])
        self.assertFalse(result["checks"]["flutter_deeplinking_disabled"])

    def test_other_application_id_cannot_satisfy_qa_expectations(self):
        result = inspector.check_manifest_dump(VALID_MANIFEST.replace('package="io.fluuix.aw.qa"', 'package="io.fluuix.aw"'), EXPECTED_MANIFEST)
        self.assertFalse(result["checks"]["package"])

    def test_optout_on_application_is_not_optout_on_activity(self):
        app_metadata = "\n".join(line[2:] for line in OPTOUT.splitlines()) + "\n"
        misplaced = VALID_MANIFEST.replace(OPTOUT, "").replace("    E: activity (line=12)", app_metadata + "    E: activity (line=12)")
        result = inspector.check_manifest_dump(misplaced, EXPECTED_MANIFEST)
        self.assertFalse(result["checks"]["flutter_deeplinking_disabled"])

    def test_callback_requires_correct_host_and_browsable_category(self):
        for output in (VALID_MANIFEST.replace('host="callback"', 'host="other"'), VALID_MANIFEST.replace('"android.intent.category.BROWSABLE"', '"android.intent.category.OTHER"')):
            with self.subTest():
                self.assertFalse(inspector.check_manifest_dump(output, EXPECTED_MANIFEST)["checks"]["callback_on_launcher"])

    def test_optout_must_be_boolean_false(self):
        for value in ("true", '"false"', "0"):
            with self.subTest(value=value):
                output = VALID_MANIFEST.replace("value=false", "value=" + value)
                self.assertFalse(inspector.check_manifest_dump(output, EXPECTED_MANIFEST)["checks"]["flutter_deeplinking_disabled"])

    def test_release_identity_comes_from_pubspec_and_flavor(self):
        with tempfile.TemporaryDirectory() as directory:
            pubspec = Path(directory) / "pubspec.yaml"
            pubspec.write_text('name: aw\nversion: "0.3.1+7"\n')
            qa = inspector.manifest_expectations(pubspec, "qa")
            production = inspector.manifest_expectations(pubspec, "production")
            self.assertEqual((qa["version_code"], qa["version_name"], qa["package"]), (7, "0.3.1-qa", "io.fluuix.aw.qa"))
            self.assertEqual((production["version_name"], production["package"]), ("0.3.1", "io.fluuix.aw"))
            pubspec.write_text("version: 0.3.1\n")
            with self.assertRaisesRegex(ValueError, "build number"):
                inspector.manifest_expectations(pubspec, "qa")

    def test_native_success_cannot_mask_stale_binary_manifest(self):
        def tool_output(command, **kwargs):
            if "--dyn-syms" in command:
                return "\n".join("1: 0 0 FUNC GLOBAL DEFAULT 1 " + name for name in inspector.EXPECTED)
            if "--dynamic" in command:
                return "0x1 (NEEDED) Shared library: [libc.so]"
            return VALID_MANIFEST.replace('"0.2.0-qa"', '"1.0-qa"')

        with tempfile.TemporaryDirectory() as directory:
            apk = Path(directory) / "stale.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("AndroidManifest.xml", b"fixture")
                archive.writestr("classes.dex", b"fixture")
                for name in ("libflutter.so", "libapp.so", "libarc_openhuman_bridge.so"):
                    archive.writestr(f"lib/arm64-v8a/{name}", elf(load(), relro()))
            with patch.object(inspector.subprocess, "check_output", side_effect=tool_output):
                result = inspector.inspect(apk, Path("mock-readelf"), Path("mock-aapt2"), EXPECTED_MANIFEST)
            self.assertTrue(all(not library["errors"] for library in result["native_libraries"]))
            self.assertEqual(result["static_checks"], "failed")
            self.assertFalse(result["manifest"]["checks"]["version_name"])


if __name__ == "__main__":
    unittest.main()
