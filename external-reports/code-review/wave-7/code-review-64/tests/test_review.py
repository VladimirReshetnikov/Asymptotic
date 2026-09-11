"""Executed independent tests; not an upstream/package acceptance suite."""
from __future__ import annotations
from fractions import Fraction as F
from math import comb, factorial
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"code"))
from lerch_rational import lerch_bounds, defining_sum_interval, _gauss, MAX_ORDER
from emit_core_patch import REPLACEMENTS, patched_text, patch_for

COUNTS = {"defining_sum_containment_cases": 0, "largest_defining_sum_terms": 0,
          "orthogonality_checks": 0, "moment_reference_comparisons": 0,
          "nested_bound_comparisons": 0, "moving_parameter_cases": 0}
QS = (F(1,5), F(1,2), F(3,4), F(9,10))
AS = (F(1,2), F(1), F(2), F(10), F(100), F(1000))


def multiply(p, q):
    result = [F(0)]*(len(p)+len(q)-1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            result[i+j] += a*b
    return result


def rising(a, n):
    result = F(1)
    for j in range(n):
        result *= a+j
    return result


def meixner_monic(q, beta, n):
    """Test-only finite hypergeometric sum, polynomial coefficients low first."""
    result, falling = [F(0)]*(n+1), [F(1)]
    r = (1-q)/q
    for j in range(n+1):
        scale = (-1)**j * comb(n,j)*r**j/rising(beta,j)
        for i, c in enumerate(falling):
            result[i] += scale*c
        falling = multiply(falling, [-F(j),F(1)])
    leading = result[-1]
    return [c/leading for c in result]


def moments(q, beta, degree):
    """Independent negative-binomial moments via Stirling/factorial moments."""
    stirling, result = [1], []
    for n in range(degree+1):
        result.append(sum((F(stirling[j])*rising(beta,j)*q**j/(1-q)**(beta+j)
                           for j in range(n+1)),F(0)))
        next_row = [0]*(n+2)
        for j in range(n+1):
            next_row[j] += j*stirling[j]
            next_row[j+1] += stirling[j]
        stirling = next_row
    return result


def evaluate(p, x):
    r = F(0)
    for c in reversed(p):
        r = r*x+c
    return r


def moment_gauss(q, a, n, beta, shift, mass_factor):
    """Independent polynomial quotient / moment construction of the approximant."""
    p = meixner_monic(q,beta,n)
    # Variable t = k - shift; denominator is t + a + shift.
    z = a + shift
    denom = evaluate(p,-z)
    quotient = [F(0)]*n
    quotient[-1] = p[-1]
    for j in range(n-2,-1,-1):
        quotient[j] = p[j+1]-z*quotient[j+1]
    mu = moments(q,beta,n-1)
    return -mass_factor*sum((v*m for v,m in zip(quotient,mu)),F(0))/denom


class CoreOperandTests(unittest.TestCase):
    def test_geometric_marker_identity(self):
        for y in (F(10),F(100),F(1000)):
            for A in (F(-3),F(2),y/2):
                u0=1/(y-A)
                for n in range(9):
                    s=sum(((-A)**j*u0**(j+1) for j in range(n+1)),F(0))
                    self.assertEqual(s-F(1,y),-(-A*u0)**(n+1)/y)

    def test_borderline_case_all_depths(self):
        for y in (F(10),F(100),F(1000)):
            for n in range(13):
                A=y/2; u0=1/(y-A)
                s=sum(((-A)**j*u0**(j+1) for j in range(n+1)),F(0))
                self.assertEqual(s,2/y if n%2==0 else 0)
                self.assertEqual(abs(s-1/y)/u0**(n+2),y**(n+1)/2**(n+2))
                COUNTS["moving_parameter_cases"] += 1

    def test_genuinely_small_moving_case(self):
        for k in (4,10,100):
            y=F(k*k); A=F(k); u0=1/(y-A)
            self.assertLess(A*u0,1)
            for n in range(9):
                s=sum(((-A)**j*u0**(j+1) for j in range(n+1)),F(0))
                self.assertEqual(abs(s-1/y)/u0**(n+2),A**(n+1)*(1-A/y))
                COUNTS["moving_parameter_cases"] += 1

    def test_fixed_controls_remain_bounded(self):
        for A in (F(-3),F(-1,2),F(2),F(3)):
            for n in range(10):
                for y in (F(10),F(100),F(1000)):
                    ratio=abs(A)**(n+1)*(1-A/y)
                    self.assertLessEqual(ratio,2*abs(A)**(n+1))

    def test_zero_perturbation_is_exact(self):
        for y in (F(10),F(100)):
            self.assertEqual(1/(y-0),1/y)


class PatchEmitterTests(unittest.TestCase):
    def setUp(self):
        self.text="(* synthetic context, not a checkout *)\n"+"\n".join(old for old,_ in REPLACEMENTS)+"\n"

    def test_replaces_both_anchors(self):
        changed=patched_text(self.text)
        for old,new in REPLACEMENTS:
            self.assertNotIn(old,changed)
            self.assertEqual(changed.count(new),1)

    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError):
            patched_text(self.text.replace(REPLACEMENTS[0][0],""))

    def test_duplicate_anchor_refused(self):
        with self.assertRaises(ValueError):
            patched_text(self.text+REPLACEMENTS[1][0])

    def test_already_patched_refused(self):
        with self.assertRaises(ValueError):
            patched_text(patched_text(self.text))

    def test_unrelated_text_preserved(self):
        self.assertTrue(patched_text(self.text).startswith("(* synthetic context, not a checkout *)\n"))

    def test_emits_unified_diff(self):
        patch=patch_for(self.text)
        self.assertTrue(patch.startswith("--- a/src/Kernel/CorePerturbation.wl\n"))
        self.assertIn("+++ b/src/Kernel/CorePerturbation.wl",patch)
        self.assertIn("+  validateInput[{core, perturbation}, limit];",patch)


class LerchTests(unittest.TestCase):
    def test_exact_q_zero(self):
        for a in AS:
            b=lerch_bounds(0,a,6)
            self.assertEqual(b.lower,1/a)
            self.assertEqual(b.width,0)
            self.assertTrue(b.exact)

    def test_known_order_one(self):
        for q in QS:
            for a in AS:
                b=lerch_bounds(q,a,1)
                self.assertEqual(b.lower,1/((1-q)*a+q))
                self.assertEqual(b.upper,1/((1-q)*a)-q/((1-q)*a*((1-q)*a+1+q)))

    def test_explicit_order_two(self):
        b=lerch_bounds(F(1,2),10,2)
        self.assertEqual((b.lower,b.upper,b.width),(F(7,38),F(47,255),F(1,9690)))

    def test_defining_sum_containment_grid(self):
        for q in QS:
            for a in AS:
                bs=[lerch_bounds(q,a,n) for n in range(1,7)]
                K=16
                while True:
                    lo,hi=defining_sum_interval(q,a,K)
                    if all(b.lower <= lo <= hi <= b.upper and
                           hi-b.lower <= b.lower_error_cap and
                           b.upper-lo <= b.upper_error_cap for b in bs):
                        break
                    K*=2
                    self.assertLessEqual(K,4096,"oracle failed to separate enclosure endpoints")
                for b in bs:
                    with self.subTest(q=q,a=a,n=b.order):
                        self.assertLessEqual(b.lower,lo)
                        self.assertLessEqual(hi,b.upper)
                        self.assertLessEqual(hi-b.lower,b.lower_error_cap)
                        self.assertLessEqual(b.upper-lo,b.upper_error_cap)
                        COUNTS["defining_sum_containment_cases"]+=1
                COUNTS["largest_defining_sum_terms"]=max(COUNTS["largest_defining_sum_terms"],K)

    def test_nested_bounds(self):
        for q in QS:
            for a in AS:
                prev=lerch_bounds(q,a,1)
                for n in range(2,13):
                    current=lerch_bounds(q,a,n)
                    self.assertLess(prev.lower,current.lower)
                    self.assertLess(current.upper,prev.upper)
                    COUNTS["nested_bound_comparisons"]+=1
                    prev=current

    def test_moment_reference(self):
        for q in QS:
            for a in (F(1,2),F(2),F(10)):
                for n in range(1,7):
                    b=lerch_bounds(q,a,n)
                    self.assertEqual(b.lower,moment_gauss(q,a,n,1,0,F(1)))
                    expected_upper=1/((1-q)*a)-moment_gauss(q,a,n,2,1,q)/a
                    self.assertEqual(b.upper,expected_upper)
                    COUNTS["moment_reference_comparisons"]+=2

    def test_meixner_orthogonality_and_norm(self):
        for q in QS:
            for beta in (1,2):
                for n in range(1,8):
                    p=meixner_monic(q,beta,n)
                    mu=moments(q,beta,2*n)
                    for j in range(n):
                        self.assertEqual(sum((p[i]*mu[i+j] for i in range(n+1)),F(0)),0)
                        COUNTS["orthogonality_checks"]+=1
                    square=multiply(p,p)
                    norm=sum((square[i]*mu[i] for i in range(2*n+1)),F(0))
                    self.assertEqual(norm,rising(beta,n)*factorial(n)*q**n/(1-q)**(2*n+beta))

    def test_positive_denominator_representation(self):
        for q in QS:
            for a in (F(1,2),F(10)):
                for beta,shift,mass in ((1,0,1/(1-q)),(2,1,q/(1-q)**2)):
                    for n in range(1,9):
                        d=rising(beta,n)*(q/(1-q))**n*sum((F(comb(n,j))*rising(a+shift,j)/rising(beta,j)*((1-q)/q)**j for j in range(n+1)),F(0))
                        g=_gauss(q,a,n,beta,shift,mass)
                        self.assertEqual(g.denominator,d)
                        self.assertGreater(d,0)

    def test_nonrational_inputs_rejected(self):
        for value in (0.5,True,"1/2",complex(1,0),None):
            with self.assertRaises(TypeError): lerch_bounds(value,10,2)
            with self.assertRaises(TypeError): lerch_bounds(F(1,2),value,2)

    def test_domain_rejected(self):
        for q,a in ((-1,1),(1,1),(2,1),(F(1,2),0),(F(1,2),-1)):
            with self.assertRaises(ValueError): lerch_bounds(q,a,2)

    def test_order_rejected(self):
        for n in (0,-1,MAX_ORDER+1):
            with self.assertRaises(ValueError): lerch_bounds(F(1,2),10,n)
        for n in (True,1.0,F(3,2)):
            with self.assertRaises(TypeError): lerch_bounds(F(1,2),10,n)

    def test_oracle_parameters_rejected(self):
        for terms in (0,-1,True):
            with self.assertRaises(ValueError): defining_sum_interval(F(1,2),10,terms)

    def test_order_limit_endpoint(self):
        b=lerch_bounds(F(1,2),10,MAX_ORDER)
        self.assertGreater(b.width,0)
        self.assertLess(b.width,lerch_bounds(F(1,2),10,2).width)


if __name__ == "__main__":
    unittest.main(verbosity=2)
