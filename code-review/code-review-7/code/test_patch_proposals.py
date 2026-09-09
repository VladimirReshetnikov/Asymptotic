"""Tests patch transformations on explicitly identified source-excerpt fixtures.
These are not tests against a full mounted checkout or a Wolfram kernel.
"""
import unittest
from emit_patch_proposals import harden_main, broaden_flat_rates, conservative_tail_proposal

class PatchProposalTests(unittest.TestCase):
    def test_two_dense_guards_and_one_power_guard(self):
        fixture = ('  coeffs = Table[0, {nmax - nmin}];\n'*2 +
          '  If[T === {},\n   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],')
        result = harden_main(fixture)
        self.assertEqual(result.count('Missing["DenseSeriesDataLimit"'), 2)
        self.assertEqual(result.count('P =!= Infinity && ! IntegerQ[rr]'), 1)
        self.assertNotIn('Table[0, {nmax - nmin}]', result)

    def test_source_drift_fails_closed(self):
        with self.assertRaises(ValueError):
            harden_main('unrelated source')

    def test_invalid_budget_fails(self):
        with self.assertRaises(ValueError):
            harden_main('', -1)

    def test_rate_transform(self):
        fixture = ''' degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase rate must be an integer multiple of the smallest rate."]];'''
        result = broaden_flat_rates(fixture)
        self.assertIn('GCD @@ (Numerator /@ degrees)', result)
        self.assertIn('LCM @@ (Denominator /@ degrees)', result)

    def test_tail_transform(self):
        result = conservative_tail_proposal('      rho = sd2[[5]]/sd2[[6]]]]]];')
        self.assertIn('(sd2[[5]] - 1/2)/sd2[[6]]', result)

if __name__ == '__main__':
    unittest.main(verbosity=2)
