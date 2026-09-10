"""Independent exact/mathematical tests; no Wolfram or Mathics is invoked."""
import unittest
import sympy as sp
import mpmath as mp
from branch_reference import endpoint_branch_reference, leading_inverse_coefficients, ReferenceRefused

x = sp.Symbol("x", real=True)
f = x + 8*x**2 - 16*x**3
g = 384*x**4 - 304*x**3 + 56*x**2 + x


def bernstein_coefficients(poly, variable, lo, hi):
    z = sp.Dummy("z")
    p = sp.Poly(sp.expand(poly.subs(variable, lo + (hi-lo)*z)), z)
    n = p.degree()
    a = [p.nth(i) for i in range(n+1)]
    return tuple(sp.simplify(sum(a[j]*sp.binomial(k, j)/sp.binomial(n, j)
                                for j in range(k+1))) for k in range(n+1))


class ExactBranchTests(unittest.TestCase):
    def test_cubic_factorization_and_roots(self):
        self.assertEqual(sp.expand(f-sp.Rational(1,2)-(x-sp.Rational(1,2))*(1-16*x*x)), 0)
        r = endpoint_branch_reference(f,x,0,sp.Rational(1,2))
        self.assertEqual(r.root,sp.Rational(1,4))
        self.assertIn(sp.Rational(1,2),r.same_side_roots)

    def test_cubic_leading_inverse_and_residual(self):
        self.assertEqual(leading_inverse_coefficients(f,x,3), (1,-8,144))
        self.assertEqual(f.subs(x,sp.Rational(1,2)),sp.Rational(1,2))
        self.assertEqual(abs(sp.Rational(1,2)-sp.Rational(1,4)),sp.Rational(1,4))

    def test_quartic_factorization_and_selected_root(self):
        factor = (2*x-1)*(4*x-1)*(8*x-1)*(12*x+1)/2
        self.assertEqual(sp.expand(g-sp.Rational(1,2)-factor),0)
        r = endpoint_branch_reference(g,x,0,sp.Rational(1,2))
        self.assertEqual(r.root,sp.Rational(1,8))
        self.assertEqual(r.same_side_roots,(sp.Rational(1,8),sp.Rational(1,4),sp.Rational(1,2)))

    def test_quartic_wrong_root_has_right_derivative_sign(self):
        self.assertEqual(sp.diff(g,x).subs(x,sp.Rational(1,2)),21)
        self.assertEqual(sp.diff(g,x).subs(x,0),1)
        self.assertEqual(abs(sp.Rational(1,2)-sp.Rational(1,8)),sp.Rational(3,8))

    def test_quartic_bernstein_monotonicity(self):
        b = bernstein_coefficients(sp.diff(g,x),x,0,sp.Rational(1,8))
        self.assertEqual(b,(1,sp.Rational(17,3),sp.Rational(67,12),sp.Rational(15,4)))
        self.assertTrue(all(v>0 for v in b))

    def test_scaled_family(self):
        # 12 exact subcases, not 12 independent package runs.
        for t in (sp.Rational(1,2),sp.Rational(1,10),sp.Rational(1,1000),sp.Rational(1,2**20)):
            for lam in (sp.Integer(2),sp.Integer(3),sp.Rational(5,2)):
                with self.subTest(t=t,lam=lam):
                    h = x+lam**2/t*x**2-lam**2/t**2*x**3
                    self.assertEqual(sp.expand(h-t-(x-t)*(1-lam**2*x**2/t**2)),0)
                    r = endpoint_branch_reference(h,x,0,t)
                    self.assertEqual(r.root,t/lam)
                    self.assertIn(t,r.same_side_roots)
                    self.assertEqual(h.subs(x,t),t)

    def test_affine_source_translation(self):
        c=sp.Rational(17,3)
        r=endpoint_branch_reference(f.subs(x,x-c),x,c,sp.Rational(1,2))
        self.assertEqual(r.root,c+sp.Rational(1,4))

    def test_reflected_source(self):
        r=endpoint_branch_reference(f.subs(x,-x),x,0,sp.Rational(1,2),side=-1)
        self.assertEqual(r.root,-sp.Rational(1,4))
        self.assertEqual(r.derivative_sign,-1)

    def test_reversed_target(self):
        r=endpoint_branch_reference(-f,x,0,-sp.Rational(1,2))
        self.assertEqual(r.root,sp.Rational(1,4))
        self.assertEqual(r.derivative_sign,-1)

    def test_linear_unbounded_component(self):
        r=endpoint_branch_reference(3*x+4,x,0,10)
        self.assertEqual(r.root,2)
        self.assertEqual(r.upper,sp.oo)

    def test_ramified_endpoint(self):
        r=endpoint_branch_reference(x**3,x,0,8)
        self.assertEqual(r.root,2)

    def test_algebraic_reference(self):
        r=endpoint_branch_reference(x**2,x,0,2)
        z=sp.Dummy("algebraic")
        self.assertEqual(sp.minpoly(r.root,z),z**2-2)
        self.assertTrue(r.root>0)

    def test_critical_target_refused(self):
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(x-x*x,x,0,sp.Rational(1,4))

    def test_nonturning_critical_point_is_conservative_stop(self):
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference((x-1)**3+1,x,0,2)

    def test_target_outside_first_component(self):
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(x-x*x,x,0,1)

    def test_invalid_exactness(self):
        for h,target in ((x+0.5*x*x,sp.Rational(1,2)),(f,0.5)):
            with self.subTest(h=h,target=target),self.assertRaises(ReferenceRefused):
                endpoint_branch_reference(h,x,0,target)

    def test_unsupported_inputs(self):
        for h in (sp.sin(x),sp.sqrt(2)*x,sp.Symbol('a')*x,sp.Integer(1)):
            with self.subTest(h=h),self.assertRaises(ReferenceRefused):
                endpoint_branch_reference(h,x,0,1)

    def test_degree_and_bit_budgets(self):
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(x**5+x,x,0,1,max_degree=4)
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(2**100*x,x,0,1,max_coefficient_bits=32)

        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(sp.Pow(x+1,10**7,evaluate=False),x,0,1)

    def test_invalid_options_and_endpoint_target(self):
        for kw in ({'side':0},{'side':True},{'max_degree':0}):
            with self.subTest(kw=kw),self.assertRaises(ReferenceRefused):
                endpoint_branch_reference(x,x,0,1,**kw)
        with self.assertRaises(ReferenceRefused):
            endpoint_branch_reference(x,x,0,0)

    def test_cubic_explicit_interval_derivative_and_bracket(self):
        lo,hi=sp.Rational(7,32),sp.Rational(9,32)
        # Elementary interval sum: 1+16[lo,hi]-48[lo^2,hi^2].
        derivative_lo=1+16*lo-48*hi**2
        self.assertEqual(derivative_lo,sp.Rational(45,64))
        self.assertLess(f.subs(x,lo),sp.Rational(1,2))
        self.assertGreater(f.subs(x,hi),sp.Rational(1,2))


class ScopedDerivativeTests(unittest.TestCase):
    def test_exact_loggamma_chain_rule(self):
        s,o=sp.symbols('s o',real=True)
        self.assertEqual(sp.diff(o+s*sp.loggamma(x),x),s*sp.polygamma(0,x))

    def test_exact_gamma_chain_rule(self):
        s,o=sp.symbols('s o',real=True)
        self.assertEqual(sp.diff(o+s*sp.gamma(x),x),s*sp.gamma(x)*sp.polygamma(0,x))

    def test_exact_witness_margins(self):
        # B(3)>1-19/108, while (1/2)psi(3)<3/4, using log(3)>1 and gamma>0.
        self.assertEqual(1-sp.Rational(19,108),sp.Rational(89,108))
        self.assertGreater(sp.Rational(89,108),sp.Rational(3,4))

    def test_positive_transformed_bound(self):
        B=sp.log(x)-1/(2*x)-1/(12*x*x)
        self.assertEqual(sp.simplify(sp.diff(B,x)-(1/x+1/(2*x*x)+1/(6*x**3))),0)
        self.assertGreater(sp.Rational(1,2)-sp.Rational(13,48),0)

    def test_transformed_bound_numeric_samples(self):
        with mp.workdps(80):
            for v in (3,8,32):
                B=mp.log(v)-mp.mpf(1)/(2*v)-mp.mpf(1)/(12*v*v)
                self.assertTrue(0<B<mp.digamma(v))

    def test_original_magnitude_bound_numeric_samples(self):
        # 18 family/scale/point subcases; numerical checks, not interval certificates.
        with mp.workdps(80):
            for family in ('LogGamma','Gamma'):
                for scale in (mp.mpf('0.5'),mp.mpf('-1'),mp.mpf('2')):
                    for v in (3,8,32):
                        with self.subTest(family=family,scale=str(scale),x=v):
                            B=mp.log(v)-mp.mpf(1)/(2*v)-mp.mpf(1)/(12*v*v)
                            jac=mp.gamma(v) if family=='Gamma' else mp.mpf(1)
                            bound=abs(scale)*jac*B
                            actual=scale*jac*mp.digamma(v)
                            self.assertTrue(0<bound<abs(actual))

    def test_scaled_counterexample_numeric(self):
        with mp.workdps(80):
            B=mp.log(3)-mp.mpf(19)/108
            self.assertGreater(B,mp.digamma(3)/2)

    def test_sign_is_distinct_from_magnitude(self):
        with mp.workdps(80):
            derivative=-mp.digamma(3)
            bound=mp.log(3)-mp.mpf(19)/108
            self.assertTrue(derivative<0<bound<abs(derivative))


if __name__ == '__main__':
    unittest.main(verbosity=2)
