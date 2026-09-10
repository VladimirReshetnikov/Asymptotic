from __future__ import annotations
import copy
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / "fixtures"), str(ROOT / "code")]
import upstream_fragments as upstream
from review_guards import (EvidenceMismatch, require_same_test_contract,
    atomic_publish_posix_mode, merge_pass_recorders, commit_receipt)


def pair():
    full = {
        "Receipt": "full.json", "PackageLayout": "modular",
        "PackageSourcesSHA256": {"src/Kernel/AsymptoticAnalysis.wl": "fixture-package"},
        "PackageFingerprintSHA256": "fixture-package-identity",
        "TestSuiteSnapshotSHA256": "fixture-suite-v1",
        "TestRunnerSnapshotSHA256": "fixture-runner-v1",
        "OriginalCounts": {"Selected": 1, "Executed": 1, "Succeeded": 0, "Failed": 1, "NotRun": 0},
        "SuccessfulTestIDs": [], "FailedTestIDs": ["same-id"],
    }
    correction = copy.deepcopy(full)
    correction.update(Receipt="correction.json", SuccessfulTestIDs=["same-id"], FailedTestIDs=[],
        OriginalCounts={"Selected": 1, "Executed": 1, "Succeeded": 1, "Failed": 0, "NotRun": 0})
    return full, correction

class ReconciliationTests(unittest.TestCase):
    def test_changed_assertion_identity_is_accepted_by_upstream_fragment(self):
        full, correction = pair()
        correction["TestSuiteSnapshotSHA256"] = "fixture-suite-v2-with-weaker-assertion"
        result = upstream.reconcile(full, correction)
        self.assertEqual(result["CorrectedTestIDs"], ["same-id"])
        self.assertTrue(result["SamePackageSources"])

    def test_candidate_rejects_changed_suite(self):
        full, correction = pair()
        correction["TestSuiteSnapshotSHA256"] = "new-suite"
        with self.assertRaisesRegex(EvidenceMismatch, "TestSuite"):
            require_same_test_contract(full, correction)

    def test_candidate_rejects_changed_runner(self):
        full, correction = pair()
        correction["TestRunnerSnapshotSHA256"] = "new-runner"
        with self.assertRaisesRegex(EvidenceMismatch, "TestRunner"):
            require_same_test_contract(full, correction)

    def test_candidate_requires_legacy_identity_migration(self):
        full, correction = pair()
        del correction["TestRunnerSnapshotSHA256"]
        with self.assertRaisesRegex(EvidenceMismatch, "Missing"):
            require_same_test_contract(full, correction)

    def test_candidate_accepts_same_contract_and_preserves_inputs(self):
        full, correction = pair()
        before = copy.deepcopy((full, correction))
        require_same_test_contract(full, correction)
        self.assertEqual(before, (full, correction))

    def test_existing_package_change_guard_remains_effective(self):
        full, correction = pair()
        correction["PackageSourcesSHA256"] = {"src/Kernel/AsymptoticAnalysis.wl": "changed"}
        with self.assertRaises(ValueError):
            upstream.reconcile(full, correction)

@unittest.skipUnless(os.name == "posix", "POSIX permission semantics")
class PublicationTests(unittest.TestCase):
    def test_upstream_sequence_replaces_0644_with_0600(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "paper.pdf"
            p.write_bytes(b"old synthetic document bytes")
            p.chmod(0o644)
            upstream.sync_publish_fragment(p, b"new synthetic document bytes")
            self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o600)
            self.assertEqual(p.read_bytes(), b"new synthetic document bytes")

    def test_candidate_preserves_0644(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "paper.pdf"
            p.write_bytes(b"old")
            p.chmod(0o644)
            atomic_publish_posix_mode(p, b"new")
            self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o644)
            self.assertEqual(p.read_bytes(), b"new")

    def test_candidate_new_files_are_private_by_default(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "paper.pdf"
            atomic_publish_posix_mode(p, b"new")
            self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o600)

    def test_candidate_new_public_mode_is_explicit(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "paper.pdf"
            atomic_publish_posix_mode(p, b"new", new_file_mode=0o644)
            self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o644)

    def test_candidate_rejects_symlink_destination(self):
        with tempfile.TemporaryDirectory() as d:
            original = Path(d) / "other"
            original.write_bytes(b"untouched")
            p = Path(d) / "paper.pdf"
            p.symlink_to(original)
            with self.assertRaises(ValueError):
                atomic_publish_posix_mode(p, b"new")
            self.assertEqual(original.read_bytes(), b"untouched")

class RecorderTests(unittest.TestCase):
    def test_candidate_union_retains_first_pass_only_input(self):
        records = [
            {"vendored_inputs": ["docs/main.tex"], "runtime_inputs": [{"path": "/first.tex", "sha256": "one"}]},
            {"vendored_inputs": ["docs/main.tex"], "runtime_inputs": []},
            {"vendored_inputs": ["docs/main.tex"], "runtime_inputs": []},
        ]
        combined = merge_pass_recorders(records)
        self.assertEqual(combined["runtime_inputs"], records[0]["runtime_inputs"])
        self.assertEqual([p["pass"] for p in combined["passes"]], [1, 2, 3])

    def test_candidate_rejects_dependency_change_between_passes(self):
        records = [{"vendored_inputs": [], "runtime_inputs": [{"path": "/a.sty", "sha256": v}]} for v in ("a", "b", "a")]
        with self.assertRaisesRegex(EvidenceMismatch, "changed"):
            merge_pass_recorders(records)

    def test_candidate_rejects_missing_field_even_with_extra_fields(self):
        records = [{"vendored_inputs": [], "irrelevant": 1}] * 3
        with self.assertRaisesRegex(EvidenceMismatch, "Incomplete"):
            merge_pass_recorders(records)

    def test_candidate_requires_all_three_passes(self):
        with self.assertRaises(EvidenceMismatch):
            merge_pass_recorders([])

    @unittest.skipUnless(shutil.which("pdflatex"), "Independent TeX recorder experiment requires pdflatex")
    def test_real_tex_last_recorder_omits_first_pass_dependency(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            mirror = root / "mirror"
            docs, out = mirror / "docs", mirror / "out"
            docs.mkdir(parents=True)
            out.mkdir()
            external = root / "first-pass-only.tex"
            external.write_text(r"\typeout{FIRST-PASS-ONLY-INPUT}" + "\n")
            source = (r"\documentclass{article}" + "\n"
                + r"\IfFileExists{probe.aux}{}{\input{" + external.as_posix() + "}}\n"
                + r"\begin{document}Recorder experiment.\end{document}" + "\n")
            (docs / "probe.tex").write_text(source)
            observations = []
            for number in range(1, 4):
                run = subprocess.run(["pdflatex", "-no-shell-escape", "-interaction=nonstopmode",
                    "-halt-on-error", "-recorder", "-output-directory=" + str(out), "probe.tex"],
                    cwd=docs, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
                self.assertEqual(run.returncode, 0, run.stdout.decode(errors="replace")[-2000:])
                observations.append(upstream.recorder_inputs(out / "probe.fls", mirror, docs))
            paths = [{item["path"] for item in record["runtime_inputs"]} for record in observations]
            self.assertIn(str(external), paths[0])
            self.assertNotIn(str(external), paths[-1])
            merged = merge_pass_recorders(observations)
            self.assertIn(str(external), {item["path"] for item in merged["runtime_inputs"]})

class RuntimeFreshnessTests(unittest.TestCase):
    def test_receipt_identity_does_not_check_recorded_runtime_file(self):
        # Synthetic receipt schema fixture; not a PDF validator or real build run.
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "docs").mkdir()
            (root / "docs/main.tex").write_bytes(b"source")
            (root / "docs/main.pdf").write_bytes(b"synthetic-pdf-content")
            style = root / "installed.sty"
            style.write_bytes(b"old runtime style")
            logs = []
            for n in range(1, 4):
                p = root / f"pass-{n}.log"
                p.write_bytes(f"synthetic successful log {n}".encode())
                logs.append({"pass": n, "returncode": 0, "timed_out": False,
                    "path": p.name, "sha256": upstream.digest(p)})
            inputs = {"docs/main.tex": upstream.digest(root / "docs/main.tex")}
            receipt = {
                "original_upstream_sha256": None, "source_inputs": inputs,
                "pass_logs": logs, "tool_versions": {"pdflatex": "fixture"},
                "pdf_check": {"page_count": 1, "validator": "synthetic schema fixture"},
                "status": "three passes and basic PDF validation succeeded",
                "sha256": upstream.digest(root / "docs/main.pdf"),
                "recorder": {"runtime_inputs": [{"path": str(style), "sha256": upstream.digest(style)}]},
            }
            self.assertTrue(upstream.receipt_matches(receipt, inputs, root, "docs/main.pdf", None))
            style.write_bytes(b"new runtime style")
            self.assertTrue(upstream.receipt_matches(receipt, inputs, root, "docs/main.pdf", None))

@unittest.skipUnless(os.name == "posix", "Candidate locking is POSIX only")
class LedgerTests(unittest.TestCase):
    def test_atomic_writes_from_stale_views_lose_other_article(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "builds.json"
            base = {"schema_version": 1, "regenerated_pdfs": {}}
            a, b = copy.deepcopy(base), copy.deepcopy(base)
            a["regenerated_pdfs"]["docs/a.pdf"] = {"attempt": "a"}
            b["regenerated_pdfs"]["docs/b.pdf"] = {"attempt": "b"}
            upstream.write_json(path, a)
            upstream.write_json(path, b)
            self.assertEqual(set(json.loads(path.read_text())["regenerated_pdfs"]), {"docs/b.pdf"})

    def test_candidate_merges_independent_article_commits(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "builds.json"
            commit_receipt(path, "docs/a.pdf", {"attempt": "a"}, expected_previous=None)
            commit_receipt(path, "docs/b.pdf", {"attempt": "b"}, expected_previous=None)
            self.assertEqual(set(json.loads(path.read_text())["regenerated_pdfs"]), {"docs/a.pdf", "docs/b.pdf"})

    def test_candidate_same_article_conflict_preserves_previous_bytes(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "builds.json"
            commit_receipt(path, "docs/a.pdf", {"attempt": "first"}, expected_previous=None)
            before = path.read_bytes()
            with self.assertRaisesRegex(EvidenceMismatch, "Concurrent"):
                commit_receipt(path, "docs/a.pdf", {"attempt": "second"}, expected_previous=None)
            self.assertEqual(path.read_bytes(), before)

    def test_candidate_explicit_previous_value_allows_update(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "builds.json"
            old = {"attempt": "first"}
            commit_receipt(path, "docs/a.pdf", old, expected_previous=None)
            commit_receipt(path, "docs/a.pdf", {"attempt": "second"}, expected_previous=old)
            self.assertEqual(json.loads(path.read_text())["regenerated_pdfs"]["docs/a.pdf"]["attempt"], "second")

class AnalyticCountermodelTests(unittest.TestCase):
    def test_complex_phase_error_cannot_use_real_prefix_lipschitz_rule(self):
        # Numerical illustration of the separate analytic proof, NOT package execution.
        values = []
        for n in (10, 100, 1000):
            # log(cosh(n)/n^(5/2)), computed without overflowing cosh.
            values.append(n - math.log(2) + math.log1p(math.exp(-2*n)) - 2.5*math.log(n))
        self.assertGreater(values[2], values[1])
        self.assertGreater(values[1], values[0])
        self.assertGreater(values[2], 900)

if __name__ == "__main__":
    unittest.main(verbosity=2)
