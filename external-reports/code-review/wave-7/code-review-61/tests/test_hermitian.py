"""Independent exact algebra checks, not Wolfram or Mathics execution."""
import sys,unittest,random
from fractions import Fraction as F
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'code'))
from hermitian_fourier import *

FREQUENCIES=[Q2(1),Q2(2),Q2(0,1),Q2(1,1),Q2(2,-1)]
def sample(rng,n=3):
    modes={ZERO:poly([rng.randrange(-2,3),rng.randrange(-2,3)])}
    for w in rng.sample(FREQUENCIES,n):
        modes[w]=poly(C2(Q2(F(rng.randrange(-3,4),2),F(rng.randrange(-1,2),3)),Q2(F(rng.randrange(-3,4),2))) for _ in range(rng.randrange(1,4)))
    return Hermitian(modes)

class AlgebraTests(unittest.TestCase):
    def test_order_and_inverse(self):
        self.assertEqual(Q2(2,-1).sign(),1)
        self.assertEqual(Q2(1,-1).sign(),-1)
        self.assertEqual(Q2(-2,1).sign(),-1)
        self.assertEqual(Q2(3,2)*Q2(3,-2),Q2(1))
        self.assertEqual(Q2(1)/Q2(3,2),Q2(3,-2))
    def test_admission(self):
        with self.assertRaises(ValueError): Hermitian({Q2(-1):poly([1])})
        with self.assertRaises(ValueError): Hermitian({ZERO:poly([C2(0,1)])})
        with self.assertRaises(ValueError): Hermitian.from_full({Q2(1):poly([1])})
    def test_cartesian_oracle(self):
        rng=random.Random(20260910)
        for i in range(80):
            with self.subTest(case=i):
                a=sample(rng,rng.randrange(1,4)); b=sample(rng,rng.randrange(1,4))
                self.assertEqual(a.mul(b).full(),full_mul(a.full(),b.full()))
                self.assertEqual(Hermitian.from_full(a.full()).modes,a.modes)
                self.assertEqual(a.full_frequency_count(),len(a.full()))
    def test_euler_and_leibniz(self):
        rng=random.Random(1781)
        for i in range(12):
            with self.subTest(case=i):
                a=sample(rng,2); b=sample(rng,2)
                self.assertEqual(a.euler().full(),full_euler(a.full()))
                self.assertEqual(a.mul(b).euler().modes,a.euler().mul(b).add(a.mul(b.euler())).modes)
    def test_trigonometric_identity(self):
        a=Hermitian({Q2(1):poly([C2(0,F(-1,2))])}) # sin(L)
        b=Hermitian({Q2(2):poly([C2(0,F(-1,2))])}) # sin(2L)
        self.assertEqual(a.mul(b).modes,{Q2(1):poly([F(1,4)]),Q2(3):poly([F(-1,4)])})
        self.assertEqual(a.mul(a).modes,{ZERO:poly([F(1,2)]),Q2(2):poly([F(-1,4)])})
    def test_work_counts(self):
        a=Hermitian({ZERO:poly([1]),Q2(1):poly([1,2]),Q2(0,1):poly([C2(1,1)])})
        b=Hermitian({ZERO:poly([2]),Q2(1):poly([1]),Q2(2):poly([C2(1,-1)]),Q2(1,1):poly([1,3])})
        half=Work(); full=Work()
        self.assertEqual(a.mul(b,half).full(),full_mul(a.full(),b.full(),full))
        self.assertEqual(full.polynomial_products,35)
        self.assertEqual(half.polynomial_products,18)
        self.assertLess(half.coefficient_products,full.coefficient_products)
    def test_lagrange_low_orders(self):
        b=Hermitian({Q2(1):poly([C2(0,F(-1,2)),C2(0,F(-1,2))])}) # (1+L)sin L
        self.assertEqual(b.lagrange_single(1).modes,b.scale_real(-1).modes)
        expected=b.mul(b).scale_real(2).add(b.mul(b.euler()))
        self.assertEqual(b.lagrange_single(2).modes,expected.modes)
    def test_lagrange_full_reference(self):
        from math import factorial
        b=Hermitian({Q2(1):poly([C2(1,1),C2(0,1)]),Q2(0,1):poly([C2(0,1)])})
        for n in range(1,5):
            with self.subTest(depth=n):
                ref={ZERO:poly([1])}
                for _ in range(n): ref=full_mul(ref,b.full())
                for j in range(1,n):
                    d=full_euler(ref)
                    for w,p in ref.items(): add_mode(d,w,pscale(p,1+n+j))
                    ref=d
                ref={w:pscale(p,F((-1)**n,factorial(n))) for w,p in ref.items()}
                ref={w:p for w,p in ref.items() if p}
                self.assertEqual(b.lagrange_single(n).full(),ref)

if __name__=='__main__': unittest.main(verbosity=2)
