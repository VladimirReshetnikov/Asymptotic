"""Executed independent mathematical/contract checks; never loads Wolfram."""
import unittest
from fractions import Fraction as F
from audit_models import *

class ContractTests(unittest.TestCase):
    def test_default_is_not_automatic_in_general(self):
        self.assertEqual(backend_choice('Series', legacy=True), 'Automatic')
        self.assertEqual(backend_choice('Series'), 'Series')
    def test_four_defaults(self):
        for b in BACKENDS:
            with self.subTest(b=b): self.assertEqual(backend_choice(b), b)
    def test_explicit_selection_wins(self):
        self.assertEqual(backend_choice('Series', ['Package']), 'Package')
    def test_first_explicit_selection_wins(self):
        self.assertEqual(backend_choice('Package', ['Series', 'Asymptotic']), 'Series')
    def test_invalid_default_is_not_silently_replaced(self):
        with self.assertRaisesRegex(ValueError, 'InvalidBackend'): backend_choice('not-a-backend')
    def test_string_symbol_name_equivalence(self):
        self.assertEqual(OptionKey('Assumptions').canonical(), OptionKey('Assumptions','System`').canonical())
    def test_context_is_not_option_identity(self):
        self.assertEqual(OptionKey('Assumptions','Global`').canonical(), OptionKey('Assumptions','System`').canonical())
    def test_different_option_names_stay_different(self):
        self.assertNotEqual(OptionKey('Direction').canonical(), OptionKey('Assumptions').canonical())
    def test_nested_function_not_a_callable_source(self):
        e=Expr('Plus',(Expr('Apply',(Expr('Function'),Expr('I'))),Expr('x')))
        self.assertTrue(protected_source(e,legacy=True)); self.assertFalse(protected_source(e))
    def test_root_polynomial_function_not_source_callable(self):
        e=Expr('Plus',(Expr('Root',(Expr('Function'),)),Expr('x')))
        self.assertTrue(protected_source(e,legacy=True)); self.assertFalse(protected_source(e))
    def test_actual_function_source_protected(self):
        self.assertTrue(protected_source(Expr('Function')))
    def test_prepared_callable_protected(self):
        self.assertTrue(protected_source(Expr('forwardCallable')))
    def test_nested_inverse_function_remains_protected(self):
        self.assertTrue(protected_source(Expr('Plus',(Expr('InverseFunction'),))))
    def test_conditional_source_remains_protected(self):
        self.assertTrue(protected_source(Expr('ConditionalExpression')))
    def test_series_source_remains_protected(self):
        self.assertTrue(protected_source(Expr('GeneralizedSeries')))
    def test_direction_spellings_protected(self):
        for key in [OptionKey('Direction'),OptionKey('Direction','System`'),OptionKey('Direction','User`')]:
            with self.subTest(key=key): self.assertTrue(protected_source(Expr('x'),[key]))
    def test_budget_spellings_protected(self):
        self.assertTrue(protected_source(Expr('x'),[OptionKey('MaxTerms','Global`')]))
    def test_assumptions_do_not_force_package(self):
        self.assertFalse(protected_source(Expr('x'),[OptionKey('Assumptions')]))
    def test_missing_interior_coefficient_is_zero(self):
        t=NativeTaylor(0,5,(F(1),F(1)))
        self.assertEqual(t.coefficient(3),0)
    def test_coefficient_beyond_frontier_is_unknown(self):
        t=NativeTaylor(0,2,(F(1),F(1)))
        with self.assertRaises(UnknownCoefficient): t.coefficient(2)
    def test_coefficient_before_first_is_zero(self):
        self.assertEqual(NativeTaylor(2,4,(F(3),)).coefficient(1),0)
    def test_endpoint_is_exclusive(self):
        t=NativeTaylor(0,4,(F(1),))
        self.assertTrue(t.covers_request(3)); self.assertFalse(t.covers_request(4))
    def test_short_native_jet_fabricates_zero(self):
        t=NativeTaylor(0,2,(F(1),F(1)))
        old=compose_identity(t,4,legacy=True)
        self.assertEqual(old,{0:F(1),1:F(1)})
        self.assertNotEqual(old.get(2,0),F(1))  # true h(x)=1+x+x^2
    def test_short_native_jet_is_refused(self):
        with self.assertRaises(UnknownCoefficient): compose_identity(NativeTaylor(0,2,(F(1),F(1))),4)
    def test_sufficient_jet_keeps_quadratic(self):
        self.assertEqual(compose_identity(NativeTaylor(0,5,(F(1),F(1),F(1))),4),{0:F(1),1:F(1),2:F(1)})
    def test_error_is_not_fourth_order(self):
        ratios=[F(1,2**k)**2/F(1,2**k)**4 for k in range(1,12)]
        self.assertEqual(ratios,[F(4**k) for k in range(1,12)])
    def test_irrelevant_ancestor_blocks_legacy_refinement(self):
        with self.assertRaises(UnknownCoefficient): replay_constant(F(20),F(4))
    def test_exact_value_needs_no_ancestor(self):
        self.assertEqual(replay_constant(F(20),F(4),optimized=True),(F(7),0))
    def test_exact_polynomial_noop_preserves_all_blocks(self):
        self.assertTrue(DerivedJet((F(0),F(1),F(3,2)),True).exact_noop(F(2)))
    def test_lower_cutoff_policy_not_changed(self):
        self.assertFalse(DerivedJet((F(0),F(2)),True).exact_noop(F(2)))
    def test_uncertain_result_not_promoted_to_exact(self):
        self.assertFalse(DerivedJet((F(0),),False).exact_noop(F(20)))
    def test_other_result_kinds_not_fast_pathed(self):
        self.assertFalse(DerivedJet((F(0),),True,kind='Native').exact_noop(F(20)))
    def test_missing_ordinary_representation_not_fast_pathed(self):
        self.assertFalse(DerivedJet((F(0),),True,ordinary_representation=False).exact_noop(F(20)))
    def test_budget_validation_precedes_noop(self):
        with self.assertRaises(ValueError): DerivedJet((F(0),),True).exact_noop(F(20),0)
    def test_exact_zero_has_no_retained_frontier(self):
        self.assertTrue(DerivedJet((),True).exact_noop(F(-7)))
    def test_order_convention_changes_quadratic_term(self):
        native={k:F(1,__import__('math').factorial(k)) for k in range(3)}
        package={k:F(1,__import__('math').factorial(k)) for k in range(2)}
        self.assertEqual(native[2],F(1,2)); self.assertNotIn(2,package)

class MathematicalTests(unittest.TestCase):
    def test_generalized_inverse_coefficients_through_seven(self):
        import sympy as s
        a,t=s.symbols('a t')
        # H + t H^a = 1; coefficients obtained independently from the product formula.
        N=7
        coeff=[s.Integer(1)]
        for n in range(1,N+1):
            product=s.prod(n*a-j for j in range(n-1))
            coeff.append(s.expand((-1)**n*product/s.factorial(n)))
        U=sum(coeff[n]*t**n for n in range(1,N+1))
        # Independent truncated polynomial convolution, not an inverse routine.
        power=s.Integer(1); rhs=s.Integer(1)
        for k in range(1,N):
            power=s.Poly(s.expand(power*U),t)
            power=sum(c*t**m[0] for m,c in power.terms() if m[0]<N)
            rhs+=s.prod(a-j for j in range(k))/s.factorial(k)*power
        residual=s.Poly(s.expand(1+U+t*rhs-1),t)
        for n in range(1,N+1):
            with self.subTest(n=n): self.assertEqual(s.simplify(residual.nth(n)),0)
    def test_quartic_root_coefficient_is_nonreal(self):
        # For real t, t^4+t+1 attains 1-3/4^(4/3)>0.
        import sympy as s
        m=1-s.Rational(3)/4**s.Rational(4,3)
        self.assertTrue(bool(m>0))

if __name__=='__main__': unittest.main(verbosity=2)
