"""Executed Python checks; these are NOT Wolfram or Mathics package tests."""
from __future__ import annotations
import json
from fractions import Fraction as F
from math import comb, factorial
from pathlib import Path
import sys
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "code"))
from lerch_enclosure import geometric_moments, lerch_enclosure, defining_series_interval


class ReferenceTests(unittest.TestCase):
    def test_known_moments(self):
        self.assertEqual(geometric_moments(F(1, 2), 5), (F(2), F(2), F(6), F(26), F(150), F(1082)))
        self.assertEqual(geometric_moments(0, 4), (F(1), F(0), F(0), F(0), F(0)))

    def test_zero_z_exactness(self):
        for s in (1, 2, 5):
            for n in range(8):
                r = lerch_enclosure(0, s, F(3, 2), n)
                self.assertEqual(r.lower, F(3, 2) ** -s)
                self.assertEqual(r.lower, r.upper)

    def test_input_contract(self):
        for args in [(0.5, 2, 10, 3), (F(1, 2), 2, 10.0, 3)]:
            with self.assertRaises(TypeError):
                lerch_enclosure(*args)
        for args in [(-1, 2, 10, 3), (1, 2, 10, 3), (F(1, 2), 0, 10, 3),
                     (F(1, 2), 2, 0, 3), (F(1, 2), 2, 10, -1),
                     (F(1, 2), 2, 10, 65), (F(1, 2), True, 10, 3)]:
            with self.assertRaises(ValueError):
                lerch_enclosure(*args)

    def test_positive_grid(self):
        rows = []
        start = time.perf_counter()
        for z in (F(1, 5), F(1, 2), F(3, 4), F(9, 10)):
            for a in (F(1, 2), F(1), F(2), F(10), F(100), F(1000)):
                for s in (1, 2, 5):
                    results = [lerch_enclosure(z, s, a, n) for n in range(8)]
                    terms = 128
                    while True:
                        qlo, qhi = defining_series_interval(z, s, a, terms)
                        if all(r.lower <= qlo <= qhi <= r.upper for r in results):
                            break
                        terms *= 2
                        if terms > 4096:
                            self.fail(f"independent interval not contained: {z=}, {a=}, {s=}")
                    for n, r in enumerate(results):
                        self.assertLessEqual(r.lower, qlo)
                        self.assertLessEqual(qhi, r.upper)
                        self.assertGreaterEqual(r.signed_remainder_lower, 0)
                        self.assertLessEqual(r.signed_remainder_upper, r.first_omitted_term_magnitude)
                        rows.append({"z": str(z), "s": s, "a": str(a), "order": n,
                                     "independent_terms": terms, "exact_containment": True,
                                     "width_ratio_to_symmetric_unsigned": float(r.width / (2*r.first_omitted_term_magnitude))})
        summary = {"kind": "independent exact rational reference checks; not package execution",
                   "grid_cases": len(rows), "grid_passed": len(rows),
                   "max_independent_terms": max(r["independent_terms"] for r in rows),
                   "elapsed_seconds_in_this_environment": time.perf_counter() - start,
                   "python": sys.version, "cases": rows}
        (ROOT / "evidence" / "python_reference_results.json").write_text(json.dumps(summary, indent=2) + "\n")

    def test_beta_moment_identities(self):
        # Polynomial integration of N*(1-v)**(N-1)*v**k, independent
        # of the closed-form moments used by lerch_enclosure.
        for n in range(1, 17):
            for k in (1, 2):
                integral = sum((F(n * (-1)**j * comb(n-1, j), j+k+1)
                                for j in range(n)), F(0))
                self.assertEqual(integral, F(factorial(k)*factorial(n), factorial(n+k)))

    def test_zeta_bound_laplace_recurrence(self):
        # The finite coefficient sum J_r(A,c) obeys
        # c*J_r-r*J_{r-1}=A**r; all checks are exact rationals.
        for a in (F(1,2), F(1), F(3), F(10)):
            for c in (F(1,2), F(1), F(2)):
                previous = F(0)
                for r in range(13):
                    value = sum((F(comb(r,j)*factorial(j))*a**(r-j)/c**(j+1)
                                 for j in range(r+1)), F(0))
                    self.assertEqual(c*value-r*previous, a**r)
                    previous = value

    def test_enclosure_width_second_order(self):
        for n in (0, 1, 3, 7):
            ratios = []
            for a in (100, 1000):
                r = lerch_enclosure(F(1, 2), 2, a, n)
                ratios.append(r.width / r.first_omitted_term_magnitude)
            # When the variance upper bound is active, normalized width ~a^-2.
            self.assertEqual(ratios[0] / ratios[1], 100)


if __name__ == "__main__":
    unittest.main(verbosity=2)
