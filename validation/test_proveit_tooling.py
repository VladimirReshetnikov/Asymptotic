"""Regression checks for the vendored-PDF tooling repairs (wave-5 report 44)."""

import json
from pathlib import Path
import tempfile
import unittest

import build_proveit_pdfs as builder


class ProveItToolingTests(unittest.TestCase):
    def test_pass_recorders_are_merged_and_kept(self):
        # T03: an input read only by the first pass survives in the union.
        first = {"pass": 1, "vendored_inputs": ["docs/a.tex", "docs/table.tex"],
                 "runtime_inputs": [{"path": "/tex/lm.sty", "sha256": "1" * 64}]}
        third = {"pass": 3, "vendored_inputs": ["docs/a.tex"],
                 "runtime_inputs": [{"path": "/tex/lm.sty", "sha256": "1" * 64},
                                    {"path": "/tex/x.sty", "sha256": "2" * 64}]}
        merged = builder.merge_pass_recorders([first, third])
        self.assertEqual(merged["vendored_inputs"], ["docs/a.tex", "docs/table.tex"])
        self.assertEqual([item["path"] for item in merged["runtime_inputs"]], ["/tex/lm.sty", "/tex/x.sty"])
        self.assertEqual(len(merged["pass_recorders"]), 2)
        with self.assertRaisesRegex(builder.BuildError, "changed between passes"):
            builder.merge_pass_recorders([first, {**third, "runtime_inputs": [{"path": "/tex/lm.sty", "sha256": "3" * 64}]}])
        with self.assertRaises(builder.BuildError):
            builder.merge_pass_recorders([])

    def test_ledger_updates_merge_fresh_state_under_a_lock(self):
        # T04: two builders holding stale snapshots both keep their entries.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "builds.json").write_text(json.dumps({"schema_version": 1, "regenerated_pdfs": {}}), encoding="utf-8")
            first = builder.read_builds(root)
            second = builder.read_builds(root)
            builder.update_builds(root, first, lambda ledger: ledger["regenerated_pdfs"].__setitem__("a.pdf", {"sha256": "a"}))
            builder.update_builds(root, second, lambda ledger: ledger["regenerated_pdfs"].__setitem__("b.pdf", {"sha256": "b"}))
            written = json.loads((root / "builds.json").read_text(encoding="utf-8"))
            self.assertEqual(sorted(written["regenerated_pdfs"]), ["a.pdf", "b.pdf"])
            self.assertEqual(sorted(second["regenerated_pdfs"]), ["a.pdf", "b.pdf"])
            self.assertFalse((root / "builds.json.lock").exists())
            (root / "builds.json.lock").write_text("stale", encoding="utf-8")
            builder.time.monotonic  # the wait uses the monotonic clock
            original = builder.time.monotonic
            clock = iter([0.0, 1000.0, 1000.0])
            builder.time.monotonic = lambda: next(clock)
            try:
                with self.assertRaisesRegex(builder.BuildError, "Timed out"):
                    builder.update_builds(root, {}, lambda ledger: None)
            finally:
                builder.time.monotonic = original
            self.assertTrue((root / "builds.json.lock").exists())


if __name__ == "__main__":
    unittest.main()
