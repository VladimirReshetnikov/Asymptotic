"""Execute mathematical witnesses and the actual retrieved standalone builder.

Python 3.9+ and mpmath. These checks do not execute Wolfram Language.
New code: MIT-0. The upstream builder fixture retains its original contents.
"""
from __future__ import annotations
from contextlib import contextmanager
import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
from typing import Optional
import unittest
import mpmath as mp

ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


builder_path = ROOT / "fixtures" / "build_standalone_upstream.py"
baseline = load_module("upstream_builder", builder_path)
patches = load_module("focused_patch_proposals", ROOT / "patches" / "apply_focused_patches.py")
patched_source = patches.transform(builder_path.read_text(encoding="utf-8"), patches.EDITS["N03"][1])
patched_namespace = {"__file__": str(builder_path), "__name__": "patched_builder"}
exec(compile(patched_source, "<patched retrieved builder>", "exec"), patched_namespace)

# Each source string is tested by assemble(), never executed as Wolfram code.
MUTATIONS = {
    "bracket_Get": 'Get["missing.wl"];',
    "qualified_bracket": 'System`Get["missing.wl"];',
    "prefix_Get": 'Get @ "missing.wl";',
    "postfix_Get": '"missing.wl" // Get;',
    "prefix_Import": 'Import @ "missing.json";',
    "postfix_Needs": '"Missing`" // Needs;',
    "Apply_Get": 'Apply[Get, {"missing.wl"}];',
    "qualified_prefix": 'System`Get @ "missing.wl";',
    "ReadList_prefix": 'ReadList @ "missing.wl";',
    "URLDownload_prefix": 'URLDownload @ "https://example.invalid/x";',
}
INERT = {
    "string": 'label = "Get @ ghost; Import[data]; $InputFileName";',
    "nested_comment": '(* Get @ ghost (* Needs @ other *) *) value = 1;',
    "larger_symbol": 'GetData = 1; Get$Helper = 2; targetGet = 3;',
    "ordinary": 'f[x_] := x^2 + 1;',
}


def assemble_fixture(namespace: dict, body: str, child: Optional[str] = None) -> bool:
    """Return whether the complete assembler accepts a temporary source tree."""
    with tempfile.TemporaryDirectory(prefix="asymptotic-audit-") as temp:
        root = Path(temp)
        kernel = root / "src" / "Kernel"
        kernel.mkdir(parents=True)
        entry = ('BeginPackage["AuditFixture`"];' + "\n" + baseline.DIRECTORY + "\n" +
                 body + "\nEndPackage[];\n")
        (kernel / "AsymptoticAnalysis.wl").write_text(entry, encoding="utf-8")
        if child is not None:
            (kernel / "Child.wl").write_text(child, encoding="utf-8")
        old = {k: namespace[k] for k in ("ROOT", "KERNEL", "TARGET")}
        namespace.update(ROOT=root, KERNEL=kernel, TARGET=root / "AsymptoticAnalysis.wl")
        try:
            result, sources = namespace["assemble"]()
            assert isinstance(result, bytes) and sources
            return True
        except ValueError:
            return False
        finally:
            namespace.update(old)


def winding_p(t):
    """Continuous 2*pi-periodic squared principal argument (endpoints agree)."""
    theta = t - 2 * mp.pi * mp.floor((t + mp.pi) / (2 * mp.pi))
    return theta * theta


def f_real(x):
    return x - x*x*winding_p(mp.log(x))


def inverse_bisect(y):
    lo, hi = y, mp.mpf(4) * y / 3
    assert f_real(lo) <= y <= f_real(hi)
    for _ in range(300):
        mid = (lo + hi) / 2
        if f_real(mid) < y:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


class IndependentAuditTests(unittest.TestCase):
    def test_retrieved_builder_exact_git_blob(self):
        payload = builder_path.read_bytes()
        blob = hashlib.sha1(b"blob " + str(len(payload)).encode("ascii") + b"\0" + payload).hexdigest()
        self.assertEqual(blob, "5bd486ac474e7ce9db757a3ef795fa5cc41afdda")

    def test_baseline_detects_bracket_calls(self):
        for label in ("bracket_Get", "qualified_bracket"):
            with self.subTest(label=label):
                self.assertFalse(assemble_fixture(baseline.__dict__, MUTATIONS[label]))

    def test_baseline_misses_eight_equivalent_dependency_forms(self):
        for label, source in MUTATIONS.items():
            if label in ("bracket_Get", "qualified_bracket"):
                continue
            with self.subTest(label=label):
                self.assertTrue(assemble_fixture(baseline.__dict__, source))

    def test_patched_builder_rejects_all_ten_forms(self):
        for label, source in MUTATIONS.items():
            with self.subTest(label=label):
                self.assertFalse(assemble_fixture(patched_namespace, source))

    def test_both_builders_accept_inert_and_unrelated_symbols(self):
        for label, source in INERT.items():
            for name, ns in (("baseline", baseline.__dict__), ("patched", patched_namespace)):
                with self.subTest(label=label, builder=name):
                    self.assertTrue(assemble_fixture(ns, source))

    def test_patched_builder_preserves_companion_inlining(self):
        statement = 'Get[FileNameJoin[{$kernelDirectory, "Child.wl"}]];'
        self.assertTrue(assemble_fixture(patched_namespace, statement, "childValue = 3;\n"))

    def test_patch_anchors_refuse_missing_or_duplicate(self):
        for key, (_, edits) in patches.EDITS.items():
            for old, new in edits:
                with self.subTest(key=key, anchor=old):
                    self.assertEqual(patches.transform(old, [(old, new)]), new)
                    with self.assertRaises(ValueError):
                        patches.transform("no anchor", [(old, new)])
                    with self.assertRaises(ValueError):
                        patches.transform(old + old, [(old, new)])

    def test_principal_log_is_not_unwrapped_log(self):
        with mp.workdps(100):
            x = mp.exp(-2 * mp.pi)
            original = mp.log(mp.power(x, 1j))**2
            rewritten = (1j * mp.log(x))**2
            self.assertLess(abs(original), mp.mpf("1e-180"))
            self.assertLess(abs(rewritten + 4 * mp.pi**2), mp.mpf("1e-90"))

    def test_counterexample_ratio_diverges_on_exact_sequence(self):
        with mp.workdps(100):
            ratios = []
            for n in range(1, 21):
                t = 2 * mp.pi * n
                # Exact-sequence formula; avoids numerical near-integer phase reduction.
                ratio = mp.exp(t) * t*t / (1 + t)**4
                ratios.append(ratio)
            self.assertTrue(all(a < b for a, b in zip(ratios, ratios[1:])))
            self.assertGreater(ratios[-1], mp.mpf("1e49"))

    def test_winding_aware_repair_bound_at_60_targets(self):
        with mp.workdps(100):
            delta = 1 / (4 * (mp.pi**2 + mp.pi))
            constant = mp.mpf(112)/27 * mp.pi**4 + mp.mpf(32)/9 * mp.pi**3
            for j in range(60):
                y = delta / 4 * mp.exp(-mp.mpf(j) / 4)
                root = inverse_bisect(y)
                approximation = y + y*y*winding_p(mp.log(y))
                self.assertLessEqual(abs(root - approximation), constant * y**3)

    def test_periodic_coefficient_lipschitz_sample(self):
        with mp.workdps(70):
            for j in range(-70, 71):
                t = mp.mpf(j)/7
                h = mp.mpf("0.001")
                self.assertLessEqual(abs(winding_p(t+h)-winding_p(t)), 2*mp.pi*h)
            for n in range(-3, 4):
                t = (2*n+1)*mp.pi
                self.assertLess(abs(winding_p(t+mp.mpf("1e-20")) -
                                    winding_p(t-mp.mpf("1e-20"))), mp.mpf("1e-60"))


def generate_evidence():
    with mp.workdps(70):
        sequence = []
        for n in (1, 2, 3, 5, 10, 20):
            t = 2*mp.pi*n
            sequence.append({"n": n, "y": mp.nstr(mp.exp(-t), 16),
                             "false_remainder_ratio": mp.nstr(mp.exp(t)*t*t/(1+t)**4, 16)})
        data = {
            "revision": patches.REVISION,
            "execution": "Python only; actual fetched builder on isolated Wolfram-source fixtures, plus independent mathematical checks",
            "native_wolfram_executed": False,
            "builder_fixture_git_blob_matches_connector": True,
            "builder_mutations": [
                {"case": label, "source": source,
                 "baseline_accepted": assemble_fixture(baseline.__dict__, source),
                 "proposed_patch_accepted": assemble_fixture(patched_namespace, source)}
                for label, source in MUTATIONS.items()
            ],
            "winding_sequence": sequence,
            "winding_bound_constant": mp.nstr(mp.mpf(112)/27*mp.pi**4 + mp.mpf(32)/9*mp.pi**3, 18),
            "mathematical_proof": "See article: g(y)=y+y^2 P(log y)+O(y^3), P(t)=Arg(exp(i t))^2",
            "limitations": ["Numerical samples are not interval certificates.",
                            "No public Wolfram counterexample or native patch pass was executed.",
                            "The complete upstream test suite was not run.",
                            "Only the Python builder was materialized exactly; there is no complete local repository checkout."]
        }
    (ROOT / "results" / "independent_evidence.json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return data


if __name__ == "__main__":
    generate_evidence()
    unittest.main(verbosity=2)
