"""Independent checks only. No repository checkout or WL interpreter is loaded."""
from fractions import Fraction as F
from math import comb
import unittest
import sympy as sp
import bootstrap_reference as ref
import bootstrap_fixed as fix
from core_model import family, local_marker_term
from emit_core_guard_patch import OLD, NEW, replace_guard, unified_diff


class CoreModelTests(unittest.TestCase):
    def test_pair_preserves_dependency_erased_by_sum(self):
        x, y = sp.symbols('x y')
        core, perturbation = x+sp.Abs(y)/2, -sp.Abs(y)/2
        self.assertFalse((core+perturbation).has(y))
        self.assertTrue(sp.Tuple(core, perturbation).has(y))

    def test_unpowered_depth_zero(self):
        a = family(F(1,2),1,0,F(100))
        self.assertEqual((a['approximation'],a['error'],a['scale']), (50,50,1))

    def test_power_two_depth_one(self):
        a = family(F(1,2),2,1,F(100))
        self.assertEqual((a['approximation'],a['error'],a['rho'],a['scale']),
                         (7500,2500,0,1))

    def test_derivative_formula_against_binomial_coefficients(self):
        for r in range(1,7):
            for n in range(1,r+2):
                with self.subTest(r=r,n=n):
                    term,u,A = local_marker_term(r,n)
                    expected = sp.binomial(r,n)*A**n*u**(n-r)
                    self.assertEqual(sp.simplify(term-expected),0)

    def test_positive_tail_before_termination(self):
        for c in (F(1,4),F(1,2),F(3,4)):
            for r in range(1,7):
                for n in range(r):
                    with self.subTest(c=c,r=r,n=n):
                        self.assertGreater(family(c,r,n,F(16))['error'],0)

    def test_exact_ratio_scaling(self):
        for c in (F(1,4),F(1,2),F(3,4)):
            for r in range(1,7):
                for n in range(r):
                    with self.subTest(c=c,r=r,n=n):
                        a = family(c,r,n,F(16))
                        b = family(c,r,n,F(32))
                        self.assertEqual(b['ratio']/a['ratio'],2**(n+1))

    def test_complete_marker_polynomial_hides_problem(self):
        for r in range(1,8):
            for n in (r,r+1):
                self.assertEqual(family(F(1,2),r,n,F(16))['error'],0)

    def test_fixed_shift_control_has_bounded_error(self):
        # x+A-lambda*A=y; the squared observable's depth-one error is A^2.
        y,A = sp.symbols('y A', positive=True)
        approx = (y-A)**2+2*A*(y-A)
        self.assertEqual(sp.expand(y**2-approx),A**2)
        self.assertEqual(sp.limit((y-(y-A)),y,sp.oo),A)

    def test_relative_perturbation_is_not_small_on_diagonal(self):
        y = sp.symbols('y', positive=True)
        c = sp.Rational(1,2)
        self.assertEqual(sp.limit(c*y/((1-c)*y),y,sp.oo),1)

    def test_domain_samples_obey_stronger_rational_threshold(self):
        # E<3, so u0<=1/4 proves u0<1/E without decimal arithmetic.
        for c in (F(1,4),F(1,2),F(3,4)):
            for y in (F(16),F(32),F(64),F(128)):
                self.assertLessEqual(1/((1-c)*y),F(1,4))

    def test_sublinear_unbounded_offset_still_breaks_bound(self):
        y = sp.symbols('y', positive=True)
        A = sp.log(1+y)
        self.assertEqual(sp.limit(A/y,y,sp.oo),0)
        # r=1,n=0: actual error is A, but the inspected formula gives scale 1.
        self.assertEqual(sp.limit(A,y,sp.oo),sp.oo)

    def test_normalized_error_identity_for_general_offset(self):
        y,A = sp.symbols('y A', positive=True)
        for r in range(1,6):
            for n in range(r):
                approx=sum(sp.binomial(r,k)*(y-A)**(r-k)*A**k for k in range(n+1))
                scale=(y-A)**(r-n-1)
                normalized=sum(sp.binomial(r,k)*A**k*(y-A)**(n+1-k)
                               for k in range(n+1,r+1))
                self.assertEqual(sp.cancel((y**r-approx)/scale-normalized),0)

    def test_invalid_family_inputs(self):
        for args in ((F(0),1,0,F(16)),(F(1),1,0,F(16)),
                     (F(1,2),0,0,F(16)),(F(1,2),1,-1,F(16))):
            with self.assertRaises(ValueError): family(*args)
        with self.assertRaises(TypeError): family(.5,1,0,F(16))


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.source = 'settings = <| counter = 1; "key" -> counter |>;\nafter = 2;\n'

    def test_reference_exposes_three_fragments(self):
        parts = ref.decode_statements(ref.mathics_bootstrap(self.source))
        self.assertEqual(len(parts),3)
        self.assertEqual(parts[0],'settings = <| counter = 1;')
        self.assertEqual(parts[1],' "key" -> counter |>;')

    def test_fixed_preserves_association_as_single_statement(self):
        parts = fix.split_statements(self.source)
        self.assertEqual(len(parts),2)
        self.assertEqual(parts[0],self.source.split('\n')[0])

    def test_constructor_spelling_metamorphism(self):
        explicit = self.source.replace('<|','Association[').replace('|>',']')
        self.assertEqual(len(fix.split_statements(explicit)),2)
        self.assertEqual(len(ref.decode_statements(ref.mathics_bootstrap(explicit))),2)
        self.assertEqual(len(fix.split_statements(self.source)),2)

    def test_association_spelling_variants(self):
        for opening,closing in ((r'\[LeftAssociation]',r'\[RightAssociation]'),
                                ('\uf113','\uf114'),('<|','|>')):
            with self.subTest(opening=opening):
                s=self.source.replace('<|',opening).replace('|>',closing)
                self.assertEqual(len(fix.split_statements(s)),2)

    def test_nested_associations_and_groups(self):
        for depth in (1,2,5,20):
            s='a='+'<|'*depth+'q=1;"k"->q'+'|>'*depth+';b=2;'
            self.assertEqual(len(fix.split_statements(s)),2)
        self.assertEqual(len(fix.split_statements('a=<|"x"->{(1;2),f[3;4]}|>;b=2;')),2)

    def test_condition_span_operators_remain_intact(self):
        source=('f[x_] /; x > 0 := x;\ng[x_] := x /; x < 0;\n'
                'span=1;;3;\nopenSpan=1;;;\nh[x_]:=Module[{},x/;x>0];\n')
        self.assertEqual([s.strip() for s in fix.split_statements(source)],source.splitlines())
        self.assertEqual(fix.split_statements(source),
                         ref.decode_statements(ref.mathics_bootstrap(source)))

    def test_strings_and_nested_comments_are_inert(self):
        s='(* <| ; (* |> ; *) *) a="<|;\\\"|>";b=<|v=1;"key"->v|>;'
        self.assertEqual(len(fix.split_statements(s)),2)
        masked=ref.executable_text(s)
        self.assertEqual(len(masked),len(s))
        self.assertEqual(masked.count('\n'),s.count('\n'))

    def test_mismatched_kind_is_rejected(self):
        for source in ('f[x};','<|a=1;"k"->a];','{x);'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                fix.split_statements(source)
        # Reference's total-depth counter cannot detect this mismatch.
        self.assertEqual(len(ref.decode_statements(ref.mathics_bootstrap('f[x};'))),1)

    def test_unclosed_association_rejected(self):
        with self.assertRaises(ValueError): fix.split_statements('a=<|x=1;')

    def test_original_unbalanced_cases_still_rejected(self):
        for source in ('f[x;','f[x]];','Module[{x},x;'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                fix.split_statements(source)

    def test_unterminated_strings_and_comments_rejected(self):
        for source in ('(* open','"open','"escape\\'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                fix.split_statements(source)

    def test_unsupported_box_grouping_rejected(self):
        with self.assertRaises(ValueError): fix.split_statements(r'a=\(x\);')

    def test_round_trip_serialized_chunks(self):
        result=fix.mathics_bootstrap(self.source)
        self.assertEqual(ref.decode_statements(result),fix.split_statements(self.source))
        self.assertEqual(''.join(fix.split_statements(self.source)),self.source.rstrip('\n'))

    def test_empty_comment_only_and_final_expression(self):
        self.assertEqual(fix.split_statements('(* only *)'),[])
        self.assertEqual(fix.split_statements(''),[])
        self.assertEqual(fix.split_statements('x=1;\nx'),['x=1;','\nx'])

    def test_generated_balanced_grammar_grid(self):
        atoms=['a','f[a;b]','{a;b}', '(a;b)', '<|a;"k"->b|>']
        for left in atoms:
            for right in atoms:
                s='z=<|'+left+';"k"->'+right+'|>;q=3;'
                with self.subTest(left=left,right=right):
                    self.assertEqual(len(fix.split_statements(s)),2)


class PatchEmitterTests(unittest.TestCase):
    def test_unique_anchor_replaced_and_neighbors_preserved(self):
        text='before;\n'+OLD+'\nafter;\n'
        self.assertEqual(replace_guard(text),'before;\n'+NEW+'\nafter;\n')

    def test_missing_anchor_refused(self):
        with self.assertRaises(ValueError): replace_guard('unrelated')

    def test_duplicate_anchor_refused(self):
        with self.assertRaises(ValueError): replace_guard(OLD+'\n'+OLD)

    def test_already_patched_refused(self):
        with self.assertRaises(ValueError): replace_guard(NEW)
        with self.assertRaises(ValueError): replace_guard(OLD+'\n'+NEW)

    def test_patch_keeps_expected_source_path(self):
        diff=unified_diff('before;\n'+OLD+'\nafter;\n')
        self.assertIn('--- a/src/Kernel/CorePerturbation.wl',diff)
        self.assertIn('+++ b/src/Kernel/CorePerturbation.wl',diff)
        self.assertIn('+  validateInput[{core, perturbation}, limit];',diff)


if __name__=='__main__': unittest.main(verbosity=2)
