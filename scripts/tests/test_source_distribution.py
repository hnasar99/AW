"""Behavioral checks for verified source archives and approved patch additions."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT / "scripts"))
import package_corresponding_source as source


class ArchiveVerificationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="aw-source-verification-test-")
        self.root = Path(self.temporary.name)
        for name in source.REQUIRED:
            destination = self.root / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(PROJECT / name, destination)
        (self.root / "patches/manifest.json").write_text("[]\n")
        self.upstream = self.root / "vendor/openhuman"
        self.upstream.mkdir(parents=True)
        (self.upstream / "lib.rs").write_text("// source verification fixture\n")
        (self.upstream / "AGENTS.md").write_text("Fixture documentation.\n")
        (self.upstream / "CLAUDE.md").symlink_to("AGENTS.md")
        files = {}
        for path in self.root.rglob("*"):
            if path.is_file() or path.is_symlink():
                name = path.relative_to(self.root).as_posix()
                files[name] = source.record_file(path, name)[0]
        self.manifest = {
            "schema": source.SCHEMA,
            "archive_root": source.ARCHIVE_ROOT,
            "source_commit": "a" * 40,
            "openhuman_commit": source.OPENHUMAN,
            "repositories": [
                {"path": ".", "commit": "a" * 40},
                {"path": "vendor/openhuman", "commit": source.OPENHUMAN},
            ],
            "patches": [],
            "files": files,
        }
        self.write_manifest()

    def tearDown(self):
        self.temporary.cleanup()

    def write_manifest(self):
        raw = (json.dumps(self.manifest, sort_keys=True) + "\n").encode()
        (self.root / source.MANIFEST).write_bytes(raw)
        (self.root / source.MANIFEST_HASH).write_text(f"{hashlib.sha256(raw).hexdigest()}  {source.MANIFEST}\n")

    def test_verified_extracted_tree_bootstraps_without_git(self):
        result = source.verify_archive(self.root)
        self.assertTrue(result["verified"])
        command = subprocess.run(["bash", "scripts/prepare_upstream.sh"], cwd=self.root, capture_output=True, text=True)
        self.assertEqual(command.returncode, 0, command.stderr)
        self.assertIn("Verified pre-applied archive", command.stdout)

    def test_modified_source_is_rejected(self):
        (self.upstream / "lib.rs").write_text("// tampered\n")
        with self.assertRaisesRegex(RuntimeError, "checksum/type/size"):
            source.verify_archive(self.root)

    def test_unlisted_upstream_file_is_rejected(self):
        (self.upstream / "injected.rs").write_text("// injected\n")
        with self.assertRaisesRegex(RuntimeError, "Unexpected/missing upstream"):
            source.verify_archive(self.root)

    def test_manifest_checksum_damage_is_rejected(self):
        (self.root / source.MANIFEST_HASH).write_text("0" * 64)
        with self.assertRaisesRegex(RuntimeError, "manifest checksum"):
            source.verify_archive(self.root)

    def test_path_traversal_is_rejected_before_reading(self):
        self.manifest["files"]["../outside"] = self.manifest["files"]["vendor/openhuman/lib.rs"]
        self.write_manifest()
        with self.assertRaisesRegex(ValueError, "Unsafe source path"):
            source.verify_archive(self.root)

    def test_source_cannot_escape_via_symlink(self):
        link = self.upstream / "CLAUDE.md"
        link.unlink()
        link.symlink_to("../../../../outside")
        with self.assertRaisesRegex(ValueError, "Unsafe source path"):
            source.verify_archive(self.root)

    def test_existing_git_never_falls_back_to_archive(self):
        (self.root / ".git").mkdir()
        command = subprocess.run(["bash", "scripts/prepare_upstream.sh"], cwd=self.root, capture_output=True, text=True)
        self.assertNotEqual(command.returncode, 0)
        self.assertNotIn("Verified pre-applied archive", command.stdout)
        with self.assertRaisesRegex(RuntimeError, "cannot replace"):
            source.verify_archive(self.root)

    @unittest.skipIf(sys.platform == "win32", "POSIX executable bits are not represented by Windows file modes")
    def test_required_executable_bit_is_checked(self):
        (self.root / "android/gradlew").chmod(0o644)
        with self.assertRaisesRegex(RuntimeError, "checksum/type/size"):
            source.verify_archive(self.root)


class PatchedCheckoutTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="aw-patched-source-test-")
        self.root = Path(self.temporary.name)
        self.repo = self.root / "vendor/openhuman"
        self.repo.mkdir(parents=True)
        subprocess.run(["git", "init", "-q", str(self.repo)], check=True)
        (self.repo / "lib.rs").write_text("old\n")
        (self.repo / ".gitignore").write_text("ignored.rs\n")
        subprocess.run(["git", "-C", str(self.repo), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.repo), "-c", "user.name=Source Test", "-c", "user.email=source-test@example.invalid", "commit", "-qm", "Fixture baseline"], check=True)
        self.revision = source.git(self.repo, "rev-parse", "HEAD").decode().strip()

    def tearDown(self):
        self.temporary.cleanup()

    def collect(self, patches):
        files, sources, repositories, omissions = {}, {}, [], []
        source.collect_repository(self.root, self.repo, self.revision, patches, files, sources, repositories, omissions)
        return files

    def test_untracked_file_from_approved_patch_is_included(self):
        patch = self.root / "patches/add-source.patch"
        patch.parent.mkdir()
        patch.write_text("diff --git a/lib.rs b/lib.rs\n--- a/lib.rs\n+++ b/lib.rs\n@@ -1 +1 @@\n-old\n+new\ndiff --git a/added.rs b/added.rs\nnew file mode 100644\n--- /dev/null\n+++ b/added.rs\n@@ -0,0 +1 @@\n+added\n")
        subprocess.run(["git", "-C", str(self.repo), "apply", str(patch)], check=True)
        patches = [{"repository": "vendor/openhuman", "upstream_commit": self.revision, "patch": "patches/add-source.patch", "sha256": hashlib.sha256(patch.read_bytes()).hexdigest()}]
        files = self.collect(patches)
        self.assertIn("vendor/openhuman/added.rs", files)
        (self.repo / "lib.rs").write_text("unauthorized\n")
        with self.assertRaisesRegex(RuntimeError, "differs from approved patches"):
            self.collect(patches)

    def test_ignored_unapproved_source_is_rejected(self):
        (self.repo / "ignored.rs").write_text("unexpected source\n")
        with self.assertRaisesRegex(RuntimeError, "Unversioned source"):
            self.collect([])


if __name__ == "__main__":
    unittest.main()
