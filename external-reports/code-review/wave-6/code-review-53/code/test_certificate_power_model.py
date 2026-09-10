"""Independent oracle tests; does not load or execute the reviewed package."""
from fractions import Fraction as F
import random
import unittest
from certificate_power_model import (
    Interval, Limits, BudgetExceeded, pow2, floor_log2, round_dyadic,
    multiply, add, reciprocal, legacy_integer_power, integer_power,
    integer_root_floor, root_point, rational_power, legacy_log_point, retry_orders,
)


def exact_power_range(a, n):
    """Independent oracle: direct Fraction exponentiation and monotonicity."""
    if n == 0:
        return Interval(1, 1)
    if n < 0 and a.lo <= 0 <= a.hi:
        raise ValueError
    endpoints = [a.lo**n, a.hi**n]
    return Interval(0 if n > 0 and n % 2 == 0 and a.lo <= 0 <= a.hi
                    else min(endpoints), max(endpoints))


class PowerAuditTests(unittest.TestCase):
    def test_odd_power_witness(self):
        a = Interval(F(-1, 4), 1)
        self.assertEqual(legacy_integer_power(a, 3, 48), a)
        self.assertEqual(integer_power(a, 3, 48), Interval(F(-1, 64), 1))

    def test_derivative_witness(self):
        a = Interval(F(-1, 4), 1)
        old = add(Interval(1, 1), multiply(Interval(4, 4), legacy_integer_power(a, 3, 48), 48), 48)
        new = add(Interval(1, 1), multiply(Interval(4, 4), integer_power(a, 3, 48), 48), 48)
        self.assertEqual(old, Interval(0, 5))
        self.assertEqual(new, Interval(F(15, 16), 5))
        self.assertEqual(F(-1, 4)+F(-1, 4)**4, F(-63, 256))
        self.assertEqual(F(-1, 2)+F(-1, 2)**4, F(-7, 16))
        self.assertEqual(1+4*F(-1, 2)**3, F(1, 2))

    def test_reflected_witness(self):
        self.assertEqual(integer_power(Interval(-1, F(1, 4)), 3), Interval(-1, F(1, 64)))

    def test_generated_integer_ranges(self):
        rng = random.Random(20260910)
        for _ in range(4000):
            lo, hi = sorted([F(rng.randint(-25,25), rng.randint(1,9)),
                             F(rng.randint(-25,25), rng.randint(1,9))])
            a, n = Interval(lo, hi), rng.randint(-12, 12)
            if n < 0 and lo <= 0 <= hi:
                continue
            exact, new, old = exact_power_range(a,n), integer_power(a,n,36), legacy_integer_power(a,n,36)
            with self.subTest(a=a,n=n):
                self.assertTrue(new.includes(exact))
                self.assertTrue(old.includes(new))

    def test_integer_limits_and_types(self):
        with self.assertRaises(BudgetExceeded): integer_power(Interval(1,2),100001)
        with self.assertRaises(TypeError): integer_power(Interval(1,2),True)
        with self.assertRaises(TypeError): Interval(0.1,1)

    def test_zero_negative_power_rejection(self):
        for a in [Interval(-1,1),Interval(0,1),Interval(-1,0)]:
            with self.assertRaises(ValueError): integer_power(a,-1)

    def test_point_powers_and_zeroth(self):
        for q in [F(-7,3),F(0),F(5,7)]:
            for n in range(0,10):
                self.assertTrue(integer_power(Interval(q,q),n).contains(q**n))
        self.assertEqual(integer_power(Interval(-1,1),0),Interval(1,1))

    def test_rounding_outward(self):
        for a in range(-50,51):
            for b in range(1,12):
                q=F(a,b)
                self.assertLessEqual(round_dyadic(q,9,False),q)
                self.assertGreaterEqual(round_dyadic(q,9,True),q)

    def test_log2_grid(self):
        for a in range(1,50):
            for b in range(1,50):
                q=F(a,b); e=floor_log2(q)
                self.assertLessEqual(pow2(e),q)
                self.assertLess(q,pow2(e+1))

    def test_integer_root_floor_exhaustive(self):
        for d in range(1,14):
            for n in range(0,600):
                m=integer_root_floor(n,d)
                self.assertLessEqual(m**d,n)
                self.assertLess(n,(m+1)**d)

    def test_large_integer_roots(self):
        for d in [2,3,7,19]:
            m=(1<<100)+123
            for delta in [-1,0,1]:
                n=m**d+delta; r=integer_root_floor(n,d)
                self.assertLessEqual(r**d,n)
                self.assertLess(n,(r+1)**d)

    def test_exact_rational_roots(self):
        self.assertEqual(root_point(F(4,9),2),Interval(F(2,3),F(2,3)))
        self.assertEqual(root_point(F(343,1000),3),Interval(F(7,10),F(7,10)))

    def test_root_enclosures_generated(self):
        rng=random.Random(417)
        for _ in range(800):
            q=F(rng.randint(1,10**8),rng.randint(1,10**8))
            d=rng.randint(2,15); bits=rng.randint(8,80)
            r=root_point(q,d,bits)
            self.assertLessEqual(r.lo**d,q)
            self.assertLessEqual(q,r.hi**d)
            self.assertLessEqual(r.hi-r.lo,pow2(1-bits)*r.lo)

    def test_negative_scale_exponents(self):
        for e in range(-41,42):
            q=F(3,5)*pow2(e)
            r=root_point(q,7,30)
            self.assertLessEqual(r.lo**7,q)
            self.assertLessEqual(q,r.hi**7)

    def test_root_resource_refusals(self):
        with self.assertRaises(BudgetExceeded): root_point(2,129)
        with self.assertRaises(BudgetExceeded): root_point(2,7,80,Limits(max_work_bits=100))
        with self.assertRaises(BudgetExceeded): root_point(1<<200,2,80,Limits(max_work_bits=100))

    def test_root_domains(self):
        self.assertEqual(root_point(0,7),Interval(0,0))
        self.assertEqual(root_point(F(2,3),1),Interval(F(2,3),F(2,3)))
        with self.assertRaises(ValueError): root_point(-1,3)
        with self.assertRaises(ValueError): root_point(2,0)
        with self.assertRaises(ValueError): root_point(2,2,1)

    def test_rational_powers_against_integer_inequalities(self):
        for lo,hi in [(F(1,9),F(7,3)),(F(2),F(5)),(F(0),F(3))]:
            for p in [-5,-2,1,2,5]:
                if lo==0 and p<0: continue
                for d in [2,3,7]:
                    power=F(p,d); r=rational_power(Interval(lo,hi),power,50)
                    lower,upper=sorted([lo**power.numerator,hi**power.numerator])
                    self.assertLessEqual(r.lo**power.denominator,lower)
                    self.assertLessEqual(upper,r.hi**power.denominator)

    def test_principal_real_domain_not_extended(self):
        with self.assertRaises(ValueError): rational_power(Interval(-8,-1),F(1,3))
        with self.assertRaises(ValueError): rational_power(Interval(0,1),F(-1,2))

    def test_large_square_root_witness(self):
        a=Interval(pow2(39998),pow2(40002))
        r=rational_power(a,F(1,2),48)
        self.assertEqual(r,Interval(pow2(19999),pow2(20001)))
        derivative=multiply(Interval(F(1,2),F(1,2)),rational_power(a,F(-1,2),48),48)
        self.assertEqual(derivative,Interval(pow2(-20002),pow2(-20000)))
        self.assertEqual(root_point(pow2(40000),2),Interval(pow2(20000),pow2(20000)))

    def test_legacy_magnitude_obstruction(self):
        for order in [2,4,10,60]:
            phase=multiply(Interval(F(1,2),F(1,2)),legacy_log_point(pow2(39998),order),4*(order+10))
            self.assertGreater(phase.lo,10000)

    def test_retry_sequence(self):
        self.assertEqual(retry_orders(6),[60,120,240,480,960,1920,2000])
        self.assertEqual(retry_orders(6,terminal=True),[60])
        self.assertEqual(retry_orders(0),[60])

    def test_retry_policy_preserves_unknown_cases(self):
        for m in range(0,21):
            self.assertEqual(len(retry_orders(m)),m+1)
            self.assertEqual(len(retry_orders(m,terminal=True)),1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
