from __future__ import annotations
import ast
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "code"))
from proof_cost_model import ProofQuery, BudgetExceeded, family, recurrence
from documentation_audit_guards import strip_tex_comments
from patch_documentation import patched_source

class ProofModelTests(unittest.TestCase):
    def test_small_counts(self):
        expected = [1, 8, 29, 92, 281, 848, 2549, 7652, 22961]
        for n, count in enumerate(expected):
            with self.subTest(n=n):
                q = ProofQuery()
                self.assertIsNone(q.evaluate(n))
                self.assertEqual(q.total_calls, count)

    def test_independent_depth_recurrence(self):
        for n in range(9):
            for depth in range(25):
                q = ProofQuery()
                q.evaluate(n, depth)
                self.assertEqual(q.total_calls, recurrence(n, depth), (n, depth))

    def test_memoization_unknown_and_real_controls(self):
        for known in (False, True):
            for n in range(11):
                for depth in (0, 1, 2, 3, 8, 16, 24):
                    p = ProofQuery(a_is_real=known)
                    q = ProofQuery(memoize=True, a_is_real=known)
                    self.assertEqual(p.evaluate(n, depth), q.evaluate(n, depth), (known, n, depth))
                    self.assertLessEqual(q.total_calls, p.total_calls)

    def test_depth_is_part_of_cache_key(self):
        q = ProofQuery(memoize=True, a_is_real=True)
        self.assertIsNone(q.evaluate(6, 1))
        self.assertIs(q.evaluate(6, 24), True)

    def test_assumptions_are_query_local(self):
        unknown = ProofQuery(memoize=True)
        known = ProofQuery(memoize=True, a_is_real=True)
        self.assertIsNone(unknown.evaluate(6))
        self.assertIs(known.evaluate(6), True)
        self.assertIsNone(unknown.evaluate(6))

    def test_family_plateau_and_memo_state_count(self):
        for n in (12, 13, 14):
            p, q = ProofQuery(), ProofQuery(memoize=True)
            self.assertIsNone(p.evaluate(n))
            self.assertIsNone(q.evaluate(n))
            self.assertEqual(p.total_calls, 335521)
            self.assertEqual(q.total_calls, 200)

    def test_fibonacci_plateau_formula(self):
        f = [0, 1]
        for _ in range(26):
            f.append(f[-1] + f[-2])
        for depth in range(25):
            # Twice the formula avoids approximate halves.
            doubled = 8*f[depth] + 4*f[depth+1] + 3*(-1)**depth - 5
            self.assertEqual(2*recurrence(25, depth), doubled)

    def test_budget_exhaustion_is_not_unknown(self):
        q = ProofQuery(max_body_calls=10)
        with self.assertRaises(BudgetExceeded):
            q.evaluate(4)
        self.assertEqual(q.total_calls, 10)
        self.assertIsNone(ProofQuery(memoize=True).evaluate(4))

    def test_input_validation(self):
        for bad in (-1, 65, True, 1.5):
            with self.assertRaises(ValueError):
                family(bad)
        with self.assertRaises(ValueError):
            ProofQuery(max_body_calls=0)

class GuardTests(unittest.TestCase):
    def test_shipped_candidate_regenerates(self):
        before = (BASE / "upstream/check_documentation.py").read_text()
        after = (BASE / "code/check_documentation_candidate.py").read_text()
        self.assertEqual(patched_source(before), after)
        self.assertFalse(any(isinstance(n, ast.Assert) for n in ast.walk(ast.parse(after))))

    def test_changed_source_is_refused(self):
        before = (BASE / "upstream/check_documentation.py").read_text()
        with self.assertRaises(ValueError):
            patched_source(before.replace("    labels = re.findall", "    labels = other_function"))

    def test_comment_and_backslash_parity(self):
        for count in range(5):
            text = "\\"*count + r"% \label{x}" + "\n"
            found = r"\label{x}" in strip_tex_comments(text)
            self.assertEqual(found, count % 2 == 1)

    def test_comment_locations_and_end_of_file(self):
        text = "abc% ignored\r\ndef% ignored\nxyz% end"
        masked = strip_tex_comments(text)
        self.assertEqual(len(masked), len(text))
        self.assertEqual([i for i,c in enumerate(text) if c in "\r\n"],
                         [i for i,c in enumerate(masked) if c in "\r\n"])
        self.assertEqual(masked.splitlines()[0].rstrip(), "abc")
        self.assertEqual(masked.splitlines()[-1].rstrip(), "xyz")

    def test_no_control_word_is_invented(self):
        text = "\\la% comment\nbel{x}"
        self.assertNotIn(r"\label{x}", strip_tex_comments(text))

    def test_comment_guard_type(self):
        with self.assertRaises(TypeError):
            strip_tex_comments(None)

    def test_require_survives_all_optimization_modes(self):
        for flag in ([], ["-O"], ["-OO"]):
            code = f"import sys;sys.path.insert(0,{str(BASE / 'code')!r});from documentation_audit_guards import require;require(False,'sentinel')"
            result = subprocess.run([sys.executable, "-S", *flag, "-c", code], text=True, capture_output=True, timeout=10)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("AssertionError: sentinel", result.stderr)

class ExecutedEvidenceTests(unittest.TestCase):
    def test_full_documentation_fixture_matrix(self):
        accepted = {"valid", "archive_crlf", "comment_duplicate", "comment_input", "valid_child"}
        path = BASE / "evidence/documentation-fixtures.json"
        records = json.loads(path.read_text())["records"]
        self.assertEqual(len(records), 56)
        for row in records:
            if row["source"] == "candidate":
                self.assertEqual(row["outcome"] == "accepted", row["case"] in accepted, row)
            if row["outcome"] == "accepted":
                self.assertEqual(row["process_exit_code"], 0)
                self.assertEqual(row["receipt"]["MissingReferences"], 0)
            else:
                self.assertNotEqual(row["process_exit_code"], 0)

    def test_live_checker_probes(self):
        for source, optimized, case, expected in (
            ("upstream/check_documentation.py", False, "missing_reference", 1),
            ("upstream/check_documentation.py", True, "missing_reference", 0),
            ("upstream/check_documentation.py", False, "comment_mask_reference", 0),
            ("code/check_documentation_candidate.py", False, "comment_mask_reference", 1),
            ("code/check_documentation_candidate.py", True, "archive_changed", 1),
            ("code/check_documentation_candidate.py", False, "comment_input", 0),
        ):
            command = [sys.executable, "-S"] + (["-O"] if optimized else []) + [str(BASE / "tests/documentation_fixture.py"), str(BASE/source), case]
            result = subprocess.run(command, text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)

    def test_real_tex_oracle_receipts(self):
        data = json.loads((BASE / "evidence/tex-oracles.json").read_text())
        self.assertTrue(data["engine_available"])
        self.assertEqual(len(data["records"]), 5)
        for row in data["records"]:
            self.assertEqual(row["exit_codes"], [0, 0])
            self.assertEqual(row["undefined_reference"], row["case"] == "comment_mask_reference")
            self.assertEqual(row["undefined_citation"], row["case"] == "comment_mask_citation")
            log = (BASE / "evidence" / f"tex-{row['case']}.log").read_text()
            self.assertIn("Output written on witness.pdf", log)

if __name__ == "__main__":
    unittest.main(verbosity=2)
