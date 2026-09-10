"""Integrity tests for final-source portable acceptance; no kernels required."""

from contextlib import redirect_stderr
import copy
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import check_mathics_acceptance as acceptance


def sample_blobs():
    return {
        acceptance.SUITE: b'$IterationLimit = 1000000;\nportableTest["sample-a", "loading", True, True];\nportableTest["sample-b", "operations", True, True];\n',
        acceptance.RUNNER: b"# frozen runner\n",
        acceptance.REQUIREMENTS: b"Mathics3==10.0.1\n",
        acceptance.ENTRY: b"standalone\n",
        acceptance.MODULAR_ENTRY: b"modular entry\n",
        "src/Kernel/Helper.wl": b"helper\n",
    }


def sample_row(test_id, group):
    kernel = "Mathics3 10.0.1 Running on linux CPython fixture"
    output = (
        f"ASYMPTOTIC_PORTABLE_KERNEL\t{kernel}\n"
        "ASYMPTOTIC_PORTABLE_ITERATION_LIMIT\t1000000\n"
        "ASYMPTOTIC_PORTABLE_ACTUAL_BEGIN\nTrue\nASYMPTOTIC_PORTABLE_ACTUAL_END\n"
        "ASYMPTOTIC_PORTABLE_EXPECTED_BEGIN\nTrue\nASYMPTOTIC_PORTABLE_EXPECTED_END\n"
        f"ASYMPTOTIC_PORTABLE_RESULT\t{test_id}\tSuccess\n"
    )
    return {"TestID": test_id, "Group": group, "Kernel": kernel,
            "KernelIterationLimit": 1000000, "Outcome": "Success", "ExitCode": 0,
            "ActualOutput": "True", "ExpectedOutput": "True", "KernelOutput": output}


def sample_report(reference, layout, test_id):
    return {
        "Runtime": "Mathics", "RunComplete": True, "SourcesUnchangedDuringRun": True,
        "FreshKernelPerCase": True, "FullPackageSuiteRun": False,
        "Selected": 1, "Executed": 1, "Succeeded": 1, "Failed": 0, "NotRun": 0,
        "Source": "/ci/repo/" + (acceptance.MODULAR_ENTRY if layout == "modular" else acceptance.ENTRY),
        "MathicsIterationLimitConfiguredBySuite": 1000000,
        "TestSuiteSnapshotSHA256": reference["FilesSHA256"][acceptance.SUITE],
        "TestedSourcesSHA256": copy.deepcopy(reference["ExpectedSources"][layout]),
        "Results": [sample_row(test_id, reference["Cases"][test_id])],
    }


class AcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.reference = acceptance.reference_from_blobs(sample_blobs(), "a" * 40)
        self.reports = [sample_report(self.reference, layout, test_id)
                        for layout in ("modular", "standalone") for test_id in self.reference["Cases"]]

    def write_reports(self):
        paths = []
        for index, report in enumerate(self.reports):
            path = self.root / f"shard-{index}.json"
            path.write_bytes((json.dumps(report, indent=2) + "\n").replace("\n", "\r\n").encode())
            paths.append(path)
        return paths

    def verify(self):
        return acceptance.verify_acceptance(self.write_reports(), self.reference, self.root)

    def test_complete_evidence_preserves_raw_hashes_and_requirements_scope(self):
        paths = self.write_reports()
        before = {path: path.read_bytes() for path in paths}
        result = acceptance.verify_acceptance(paths, self.reference, self.root)
        self.assertTrue(result["Accepted"])
        self.assertEqual(result["CasesPerLayout"], 2)
        self.assertEqual(result["SuccessfulObservations"], 4)
        self.assertEqual(result["RequirementsEvidence"], {"NotRecorded": 4})
        self.assertEqual([receipt["ReceiptSHA256"] for receipt in result["Receipts"]],
                         [acceptance.sha256(before[path]) for path in paths])
        self.assertTrue(all(path.read_bytes() == body for path, body in before.items()))

    def test_missing_case_or_entire_layout_cannot_pass(self):
        for remove in (1, 2):
            with self.subTest(remove=remove):
                reports = self.reports[:len(self.reports) - remove]
                with patch.object(self, "reports", reports), self.assertRaisesRegex(ValueError, "missing IDs"):
                    self.verify()

    def test_duplicate_id_across_shards_cannot_replace_missing_case(self):
        self.reports[1] = copy.deepcopy(self.reports[0])
        with self.assertRaisesRegex(ValueError, "duplicate IDs"):
            self.verify()

    def test_duplicate_id_within_shard_is_rejected(self):
        report = self.reports[0]
        report["Results"] *= 2
        report.update(Selected=2, Executed=2, Succeeded=2)
        with self.assertRaisesRegex(ValueError, "within a shard"):
            self.verify()

    def test_unknown_id_or_group_is_rejected(self):
        for key, value in (("TestID", "unknown-case"), ("Group", "unknown")):
            with self.subTest(key=key):
                reports = copy.deepcopy(self.reports)
                reports[0]["Results"][0][key] = value
                with patch.object(self, "reports", reports), self.assertRaises(ValueError):
                    self.verify()

    def test_incomplete_or_drifting_receipt_is_rejected(self):
        for key, value in (("RunComplete", False), ("SourcesUnchangedDuringRun", False),
                           ("FreshKernelPerCase", False), ("NotRun", 1), ("Executed", 0),
                           ("Succeeded", True)):
            with self.subTest(key=key):
                reports = copy.deepcopy(self.reports)
                reports[0][key] = value
                with patch.object(self, "reports", reports), self.assertRaises(ValueError):
                    self.verify()

    def test_missing_extra_or_changed_module_is_rejected(self):
        for mutation in ("missing", "extra", "changed"):
            with self.subTest(mutation=mutation):
                reports = copy.deepcopy(self.reports)
                sources = reports[0]["TestedSourcesSHA256"]
                if mutation == "missing":
                    del sources["src/Kernel/Helper.wl"]
                elif mutation == "extra":
                    sources["src/Kernel/Extra.wl"] = "0" * 64
                else:
                    sources["src/Kernel/Helper.wl"] = "0" * 64
                with patch.object(self, "reports", reports), self.assertRaisesRegex(ValueError, "source set or hashes"):
                    self.verify()

    def test_suite_snapshot_suite_file_and_runner_are_each_checked(self):
        for key in ("snapshot", acceptance.SUITE, acceptance.RUNNER):
            with self.subTest(key=key):
                reports = copy.deepcopy(self.reports)
                if key == "snapshot":
                    reports[0]["TestSuiteSnapshotSHA256"] = "0" * 64
                else:
                    reports[0]["TestedSourcesSHA256"][key] = "0" * 64
                with patch.object(self, "reports", reports), self.assertRaises(ValueError):
                    self.verify()

    def test_relocated_windows_and_relative_kernel_paths_keep_all_modules(self):
        first = self.reports[0]
        first["Source"] = r"C:\frozen\Kernel\AsymptoticAnalysis.wl"
        first["TestedSourcesSHA256"] = {
            (name.replace("src/Kernel/", "Kernel/") if name.startswith("src/Kernel/")
             else "C:\\frozen\\" + name.replace("/", "\\")): digest
            for name, digest in first["TestedSourcesSHA256"].items()}
        self.assertTrue(self.verify()["Accepted"])

    def test_layout_mismatch_and_duplicate_canonical_sources_are_rejected(self):
        reports = copy.deepcopy(self.reports)
        reports[0]["Source"] = "/ci/repo/AsymptoticAnalysis.wl"
        with patch.object(self, "reports", reports), self.assertRaisesRegex(ValueError, "source set or hashes"):
            self.verify()
        self.reports[0]["TestedSourcesSHA256"]["Kernel/Helper.wl"] = self.reference["FilesSHA256"]["src/Kernel/Helper.wl"]
        with self.assertRaisesRegex(ValueError, "Duplicate canonical"):
            self.verify()

    def test_unknown_source_and_contradictory_after_hashes_are_rejected(self):
        reports = copy.deepcopy(self.reports)
        reports[0]["TestedSourcesSHA256"]["unrecorded.py"] = "0" * 64
        with patch.object(self, "reports", reports), self.assertRaisesRegex(ValueError, "Unexpected fingerprinted"):
            self.verify()
        self.reports[0]["SourcesSHA256AfterRun"] = dict(self.reports[0]["TestedSourcesSHA256"])
        self.reports[0]["SourcesSHA256AfterRun"][acceptance.RUNNER] = "0" * 64
        with self.assertRaisesRegex(ValueError, "Contradictory"):
            self.verify()

    def test_forged_success_and_wrong_exit_or_kernel_are_rejected(self):
        mutations = [
            lambda row: row.update(ExitCode=1),
            lambda row: row.update(ExitCode=False),
            lambda row: row.update(Kernel="Wolfram 15"),
            lambda row: row.update(KernelOutput=row["KernelOutput"].replace("\tSuccess\n", "\tFailure\n")),
            lambda row: row.update(KernelIterationLimit=4096),
            lambda row: row.update(ActualOutput="False"),
            lambda row: row.update(KernelOutput=row["KernelOutput"] + "ASYMPTOTIC_PORTABLE_RESULT\tsample-a\tSuccess\n"),
        ]
        for index, mutation in enumerate(mutations):
            with self.subTest(index=index):
                reports = copy.deepcopy(self.reports)
                mutation(reports[0]["Results"][0])
                with patch.object(self, "reports", reports), self.assertRaises(ValueError):
                    self.verify()

    def test_optional_requirements_hash_is_verified_or_rejected(self):
        self.reports[0]["RequirementsSHA256"] = self.reference["FilesSHA256"][acceptance.REQUIREMENTS]
        self.assertEqual(self.verify()["RequirementsEvidence"], {"Verified": 1, "NotRecorded": 3})
        self.reports[0]["RequirementsSHA256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "requirements hash"):
            self.verify()

    def test_duplicate_json_members_are_rejected(self):
        paths = self.write_reports()
        path = paths[0]
        path.write_bytes(path.read_bytes().replace(b'"Runtime": "Mathics",', b'"Runtime": "Mathics", "Runtime": "Mathics",'))
        with self.assertRaisesRegex(ValueError, "Duplicate JSON member"):
            acceptance.verify_acceptance(paths, self.reference, self.root)

    def test_output_input_collision_is_rejected_before_git_or_writing(self):
        paths = self.write_reports()
        argv = ["verify", "--receipts", str(self.root), "--revision", "HEAD", "--output", str(paths[0])]
        before = paths[0].read_bytes()
        with patch("sys.argv", argv), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as error:
            acceptance.main()
        self.assertEqual(error.exception.code, 2)
        self.assertEqual(paths[0].read_bytes(), before)

    @unittest.skipUnless(shutil.which("git"), "Git is required for immutable-blob test")
    def test_git_reference_ignores_dirty_tree_and_preserves_blob_newlines(self):
        repository = self.root / "repository"
        repository.mkdir()
        def git(*args):
            return subprocess.check_output(["git", "-C", str(repository), *args], stderr=subprocess.DEVNULL)
        git("init")
        git("config", "core.autocrlf", "false")
        original = sample_blobs()
        original[acceptance.SUITE] = original[acceptance.SUITE].replace(b"\n", b"\r\n")
        for name, body in original.items():
            path = repository / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(body)
        git("add", ".")
        git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "reference")
        commit = git("rev-parse", "HEAD").decode().strip()
        (repository / acceptance.SUITE).write_bytes(b"dirty unrelated suite\n")
        (repository / "src/Kernel/Helper.wl").write_bytes(b"changed helper\n")
        reference = acceptance.git_reference(repository, commit)
        self.assertEqual(reference["Cases"], self.reference["Cases"])
        self.assertEqual(reference["FilesSHA256"][acceptance.SUITE], acceptance.sha256(original[acceptance.SUITE]))
        self.assertEqual(reference["FilesSHA256"]["src/Kernel/Helper.wl"], acceptance.sha256(original["src/Kernel/Helper.wl"]))


if __name__ == "__main__":
    unittest.main()
