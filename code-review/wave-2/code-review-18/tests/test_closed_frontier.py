from __future__ import annotations
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'code'))
import random
import unittest
from fractions import Fraction as F
import sympy as s
from closed_frontier import pushforward, BudgetExceeded
L, t = s.symbols('L t')

class ClosedFrontierTests(unittest.TestCase):
    def run_case(self, rows, coefficient, p=F(2), d=0, cut=F(3), budget=20000):
        return pushforward(rows, coefficient, input_power=p, input_log_degree=d,
                           cutoff=cut, log=L, max_pair_products=budget)

    def test_exponential_regression(self):
        q=self.run_case([(F(1),L)],lambda k:1/s.factorial(k))
        self.assertEqual(q.terms,{F(1):L})
        self.assertEqual(q.boundary_polynomial,L**2/2)
        self.assertEqual(q.remainder_log_degree,2)

    def test_logarithm_regression(self):
        q=self.run_case([(F(1),L)],lambda k:s.Rational((-1)**(k+1),k))
        self.assertEqual(q.boundary_polynomial,-L**2/2)
        self.assertEqual(q.remainder_log_degree,2)

    def test_square_root_regression(self):
        q=self.run_case([(F(1),L)],lambda k:s.binomial(s.Rational(1,2),k))
        self.assertEqual(q.boundary_polynomial,-L**2/8)
        self.assertEqual(q.remainder_log_degree,2)

    def test_high_degree_later_block_does_not_pollute_boundary(self):
        q=self.run_case([(F(1),L),(F(3,2),L**10)],lambda k:1/s.factorial(k))
        self.assertEqual(q.boundary_polynomial,L**2/2)
        self.assertEqual(q.remainder_log_degree,2) # coarse N*max_degree is 20

    def test_nonresonant_frontier(self):
        q=self.run_case([(F(1),L)],lambda k:1/s.factorial(k),p=F(5,2),cut=F(3))
        self.assertEqual(q.boundary_polynomial,0)
        self.assertEqual(q.remainder_log_degree,0)
        self.assertEqual(q.terms[F(2)],L**2/2)

    def test_input_error_survives_cancellation(self):
        q=self.run_case([(F(1),L)],lambda k:0,p=F(2),d=7)
        self.assertEqual(q.remainder_log_degree,7)

    def test_coefficients_called_once_and_in_order(self):
        seen=[]
        def cf(k):
            seen.append(k)
            return s.Rational(1,s.factorial(k))
        q=self.run_case([(F(1),L)],cf,p=F(4),cut=F(5))
        self.assertEqual(seen,[1,2,3,4])
        self.assertEqual(q.coefficient_calls,4)

    def test_termination_marker(self):
        seen=[]
        def cf(k):
            seen.append(k)
            return 1 if k==1 else None
        q=self.run_case([(F(1),L)],cf,p=F(5),cut=F(6))
        self.assertEqual(seen,[1,2])
        self.assertEqual(q.boundary_polynomial,0)

    def test_budget_failure(self):
        with self.assertRaises(BudgetExceeded):
            self.run_case([(F(1,2),L),(F(1),1)],lambda k:1,budget=1)

    def test_invalid_float_weight(self):
        with self.assertRaises(TypeError):
            self.run_case([(0.5,L)],lambda k:1)

    def test_invalid_nonpositive_weight(self):
        with self.assertRaises(ValueError):
            self.run_case([(F(0),L)],lambda k:1)

    def test_invalid_unretained_input(self):
        with self.assertRaises(ValueError):
            self.run_case([(F(2),L)],lambda k:1)

    def test_independent_dense_polynomial_oracle(self):
        rng=random.Random(20260909)
        for trial in range(40):
            rows=[(F(j,2), s.Integer(rng.randint(-2,2))*L**rng.randint(0,4))
                  for j in range(1,5)]
            rows=[(w,p) for w,p in rows if p!=0]
            if not rows:
                rows=[(F(1,2),s.S.One)]
            p=F(5,2)
            q=self.run_case(rows,lambda k:1/s.factorial(k),p=p,cut=F(3))
            # Independent oracle: one ordinary polynomial in t, with u=t^2.
            poly=sum(a*t**int(2*w) for w,a in rows)
            n=int(p/min(w for w,_ in rows))
            direct=s.Poly(s.expand(sum(poly**k/s.factorial(k) for k in range(1,n+1))),t)
            expected={F(j,2):s.expand(direct.coeff_monomial(t**j))
                      for j in range(1,5) if direct.coeff_monomial(t**j)!=0}
            with self.subTest(trial=trial):
                self.assertEqual(q.terms,expected)
                self.assertEqual(q.boundary_polynomial,s.expand(direct.coeff_monomial(t**5)))

if __name__=='__main__':
    unittest.main(verbosity=2)
