"""Characterization tests pass when the upstream gap is reproduced.

Candidate tests instead require rejection/preservation according to the new
explicit policy. These tests use actual Pandoc, but only temporary repositories.
"""
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

BASE = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(BASE / "code"), str(BASE / "fixtures")]
from portable_links import check_portable_links
from documentation_links_upstream import check_local_links


@unittest.skipUnless(shutil.which("pandoc"), "Pandoc is required")
class LinkTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.workspace = Path(self.tmp.name)
        self.root = self.workspace / "repo"
        self.docs = self.root / "docs"
        self.docs.mkdir(parents=True)
        self.page = self.docs / "Guide.md"
        (self.root / "README.md").write_text("# Overview\n", encoding="utf-8")
        self.outside = self.workspace / "outside.md"
        self.outside.write_text("# Outside\n", encoding="utf-8")

    def source(self, text):
        self.page.write_text(text, encoding="utf-8")

    def make_symlink(self, link, target):
        try:
            link.symlink_to(target)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f"Symlink creation unavailable: {exc}")

    def new_check(self):
        return check_portable_links(self.root, [self.page])

    def reject(self, text, message):
        self.source(text)
        with self.assertRaisesRegex(AssertionError, message):
            self.new_check()

    def test_upstream_accepts_existing_parent_escape(self):
        self.source("[outside](../../outside.md#outside)\n")
        self.assertEqual(check_local_links([self.page])["BrokenLocalLinks"], 0)

    def test_upstream_result_changes_when_unrelated_file_disappears(self):
        self.source("[outside](../../outside.md)\n")
        self.assertEqual(check_local_links([self.page])["BrokenLocalLinks"], 0)
        self.outside.unlink()
        with self.assertRaisesRegex(AssertionError, "Missing destination"):
            check_local_links([self.page])

    def test_upstream_accepts_absolute_filesystem_target(self):
        self.source(f"[outside]({self.outside.as_posix()})\n")
        self.assertEqual(check_local_links([self.page])["BrokenLocalLinks"], 0)

    def test_candidate_rejects_parent_escape(self):
        self.reject("[outside](../../outside.md)", "escapes the checkout")

    def test_candidate_rejects_encoded_parent_escape(self):
        self.reject("[outside](%2e%2e/%2e%2e/outside.md)", "escapes the checkout")

    def test_candidate_rejects_absolute_filesystem_path(self):
        self.reject(f"[outside]({self.outside.as_posix()})", "root-relative")

    def test_candidate_allows_parent_within_checkout(self):
        self.source("[overview](../README.md#overview)\n")
        self.assertEqual(self.new_check()["LocalFragments"], 1)

    def test_candidate_allows_own_fragment(self):
        self.source("# Here\n\n[here](#here)\n")
        self.assertEqual(self.new_check()["LocalFragments"], 1)

    def test_candidate_checks_html_fragment(self):
        (self.docs / "page.html").write_text('<h1 id="hello">Hello</h1>', encoding="utf-8")
        self.source("[hello](page.html#hello)")
        self.assertEqual(self.new_check()["LocalFragments"], 1)

    def test_candidate_rejects_missing_fragment(self):
        self.reject("[missing](../README.md#absent)", "missing fragment")

    def test_candidate_rejects_wrong_case(self):
        self.reject("[wrong](../readme.md)", "differently cased")

    def test_candidate_checks_images(self):
        self.reject("![image](../../outside.md)", "escapes the checkout")

    def test_candidate_rejects_file_url(self):
        self.reject(f"[local]({self.outside.as_uri()})", "file: URL")

    def test_candidate_leaves_external_links_out_of_scope(self):
        self.source("[web](https://example.invalid/x)\n[mail](mailto:x@example.invalid)")
        self.assertEqual(self.new_check()["LocalLinks"], 0)

    def test_candidate_rejects_external_symlink(self):
        self.make_symlink(self.docs / "alias.md", self.outside)
        self.reject("[alias](alias.md)", "symlink")

    def test_candidate_explicitly_rejects_internal_symlink(self):
        self.make_symlink(self.docs / "alias.md", self.root / "README.md")
        self.reject("[alias](alias.md)", "symlink")

    def test_candidate_rejects_source_outside_root(self):
        with self.assertRaisesRegex(AssertionError, "Invalid source"):
            check_portable_links(self.root, [self.outside])

    def test_candidate_accepts_url_escaped_spaces(self):
        (self.docs / "with space.md").write_text("# Heading\n", encoding="utf-8")
        self.source("[space](with%20space.md#heading)")
        self.assertEqual(self.new_check()["LocalFragments"], 1)

    def test_candidate_still_rejects_missing_destination(self):
        self.reject("[missing](never-created.md)", "missing or differently cased")


if __name__ == "__main__":
    unittest.main(verbosity=2)
