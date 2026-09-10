"""Evidence-boundary tests for the portable receipt summarizer."""

import copy
from contextlib import redirect_stderr
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from summarize_mathics_tests import build_summary, main, package_hashes, read_receipt, reconcile


class SummaryEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.full = {
            "Receipt": "full.json", "PackageLayout": "modular",
            "PackageSourcesSHA256": {"src/Kernel/AsymptoticAnalysis.wl": "original"},
            "PackageFingerprintSHA256": "fingerprint",
            "OriginalCounts": {"Selected": 2, "Executed": 2, "Succeeded": 1, "Failed": 1, "NotRun": 0},
            "SuccessfulTestIDs": ["a"], "FailedTestIDs": ["b"],
        }
        self.correction = copy.deepcopy(self.full)
        self.correction.update(Receipt="correction.json", SuccessfulTestIDs=["b"], FailedTestIDs=[])

    def test_reconciliation_retains_original_failure_and_input(self):
        before = copy.deepcopy(self.full)
        summary = build_summary([(self.full, self.correction)], [])
        self.assertEqual(summary["UniqueCasesWithSuccessfulEvidenceAcrossRecordedSnapshots"], 2)
        self.assertEqual(summary["Reconciliations"][0]["OriginalFullRunCounts"]["Failed"], 1)
        self.assertEqual(summary["Reconciliations"][0]["OriginalFailedTestIDsRetained"], ["b"])
        self.assertFalse(summary["SingleFullCurrentSourceAcceptanceClaimed"])
        self.assertEqual(self.full, before)

    def test_changed_package_cannot_be_reconciled(self):
        self.correction["PackageSourcesSHA256"]["src/Kernel/AsymptoticAnalysis.wl"] = "different"
        with self.assertRaisesRegex(ValueError, "different package"):
            reconcile(self.full, self.correction)

    def test_partial_correction_does_not_erase_unresolved_failure(self):
        self.correction["SuccessfulTestIDs"] = ["a"]
        with self.assertRaisesRegex(ValueError, "every original failure"):
            reconcile(self.full, self.correction)

    def test_modular_paths_normalize_but_test_changes_do_not_change_package(self):
        original = {"TestedSourcesSHA256": {"src/Kernel/AsymptoticAnalysis.wl": "source", "validation/MathicsTests.wl": "old"}}
        relocated = {"TestedSourcesSHA256": {"C:\\frozen\\src\\Kernel\\AsymptoticAnalysis.wl": "source", "validation/MathicsTests.wl": "new"}}
        self.assertEqual(package_hashes(original), package_hashes(relocated))

    def test_output_cannot_overwrite_an_input_receipt(self):
        argv = ["summary", "--supplemental", "receipt.json", "--output", "receipt.json"]
        with patch("sys.argv", argv), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
            main()
        self.assertEqual(error.exception.code, 2)

    def test_relative_kernel_companion_change_is_not_dropped(self):
        before = {"TestedSourcesSHA256": {"Kernel/AsymptoticAnalysis.wl": "entry", "Kernel/SeriesOperations.wl": "old"}}
        after = copy.deepcopy(before)
        after["TestedSourcesSHA256"]["Kernel/SeriesOperations.wl"] = "changed"
        self.assertNotEqual(package_hashes(before), package_hashes(after))
        self.assertEqual(set(package_hashes(before)), {
            "src/Kernel/AsymptoticAnalysis.wl", "src/Kernel/SeriesOperations.wl"})

    def test_receipt_hash_survives_crlf_publication_without_rehashing_tested_sources(self):
        package_hash = hashlib.sha256(b"package\r\nsource\r\n").hexdigest()
        suite_hash = hashlib.sha256(b"historical\r\nsuite\r\n").hexdigest()
        report = {
            "Runtime": "Mathics", "RunComplete": True, "SourcesUnchangedDuringRun": True,
            "UTC": "2026-09-10T00:00:00+00:00", "Source": "src/Kernel/AsymptoticAnalysis.wl",
            "TestedSourcesSHA256": {"src/Kernel/AsymptoticAnalysis.wl": package_hash},
            "TestSuiteSnapshotSHA256": suite_hash,
            "Selected": 1, "Executed": 1, "Succeeded": 1, "Failed": 0, "NotRun": 0,
            "Results": [{"TestID": "exact-case", "Outcome": "Success"}],
        }
        published = (json.dumps(report, indent=2) + "\n").encode()
        working_copy = published.replace(b"\n", b"\r\n")
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "receipt.json"
            path.write_bytes(working_copy)
            from_crlf = read_receipt(path)
            self.assertEqual(path.read_bytes(), working_copy)
            path.write_bytes(published)
            from_lf = read_receipt(path)
            self.assertEqual(path.read_bytes(), published)
        self.assertEqual(from_crlf, from_lf)
        self.assertEqual(from_lf["ReceiptSHA256"], hashlib.sha256(published).hexdigest())
        self.assertNotEqual(from_lf["ReceiptSHA256"], hashlib.sha256(working_copy).hexdigest())
        self.assertEqual(from_lf["ReceiptSHA256Normalization"], "CRLF-to-LF; all other bytes unchanged")
        self.assertEqual(from_lf["PackageSourcesSHA256"], {
            "src/Kernel/AsymptoticAnalysis.wl": package_hash})
        self.assertEqual(from_lf["TestSuiteSnapshotSHA256"], suite_hash)


if __name__ == "__main__":
    unittest.main()
