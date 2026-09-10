"""Independent audit models; NOT a Wolfram Language or Mathics interpreter.

The interval model transcribes the bounded rational arithmetic in the pinned
InverseCertificates.wl. The AST model isolates one held-tree rewrite only.
The floating model reproduces a 53-bit arithmetic policy, not a Mathics run.
Original review code: MIT-0. Python >=3.10; mpmath 1.3.0 for log experiments.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from typing import Union, Iterable

Interval = tuple[F, F]


def pow2(k: int) -> F:
    return F(2**k) if k >= 0 else F(1, 2**(-k))


@dataclass
class Arithmetic:
    bits: int = 48
    multiplications: int = 0
    squares: int = 0
    rounding_calls: int = 0

    def __post_init__(self) -> None:
        if not isinstance(self.bits, int) or self.bits < 2:
            raise ValueError('bits must be an integer >= 2')

    def rounded(self, q: F, upper: bool) -> F:
        q = F(q)
        self.rounding_calls += 1
        if not q:
            return F(0)
        a = abs(q)
        exponent = a.numerator.bit_length() - a.denominator.bit_length()
        if a < pow2(exponent):
            exponent -= 1
        grid = pow2(exponent - self.bits + 1)
        scaled = q / grid
        cell = (-((-scaled.numerator) // scaled.denominator) if upper
                else scaled.numerator // scaled.denominator)
        return grid * cell

    def rounded_interval(self, a: Interval) -> Interval:
        return self.rounded(a[0], False), self.rounded(a[1], True)

    def add(self, a: Interval, b: Interval) -> Interval:
        return self.rounded_interval((a[0] + b[0], a[1] + b[1]))

    def multiply(self, a: Interval, b: Interval) -> Interval:
        self.multiplications += 1
        products = [x*y for x in a for y in b]
        return self.rounded_interval((min(products), max(products)))

    def reciprocal(self, a: Interval) -> Interval:
        if a[0] <= 0 <= a[1]:
            raise ZeroDivisionError('interval contains zero')
        return self.rounded_interval((1/a[1], 1/a[0]))

    def power(self, a: Interval, n: int, patched: bool = False) -> Interval:
        if not isinstance(n, int):
            raise TypeError('integer exponent required')
        if abs(n) > 100000:
            raise ValueError('integer exponent resource cap')
        if a[0] > a[1]:
            raise ValueError('reversed interval')
        # Candidate repair: preserve odd-power monotonic endpoint geometry,
        # but retain bounded directed arithmetic in the endpoint evaluations.
        if patched and n > 1 and n % 2 and a[0] < 0 < a[1]:
            lo = self.power((a[0], a[0]), n, patched=True)[0]
            hi = self.power((a[1], a[1]), n, patched=True)[1]
            return lo, hi
        base = tuple(map(F, a))
        power = abs(n)
        answer = F(1), F(1)
        if n < 0:
            base = self.reciprocal(base)
        while power > 0:
            if power % 2:
                answer = self.multiply(answer, base)
            power //= 2
            if power:
                self.squares += 1
                if base[0] <= 0 <= base[1]:
                    base = self.rounded_interval((F(0), max(base[0]**2, base[1]**2)))
                else:
                    base = self.rounded_interval(tuple(sorted((base[0]**2, base[1]**2))))
        return answer


def exact_power_hull(a: Interval, n: int) -> Interval:
    """Independent mathematical endpoint oracle, for bounded test exponents."""
    lo, hi = a
    if n < 0 and lo <= 0 <= hi:
        raise ZeroDivisionError('interval contains zero')
    if n == 0:
        return F(1), F(1)
    ends = [lo**n, hi**n]
    if n > 0 and n % 2 == 0 and lo <= 0 <= hi:
        ends.append(F(0))
    return min(ends), max(ends)


def certificate_witness() -> dict:
    """Derivative-interval stage and exact residual, not full certificate API."""
    base = F(-1, 4), F(1)
    one16 = F(1, 16), F(1, 16)
    old = Arithmetic().add(Arithmetic().power(base, 3), one16)
    new = Arithmetic().add(Arithmetic().power(base, 3, True), one16)
    f = lambda x: (x-1)**4/F(4) + x/F(16)
    return {
        'function': '(x-1)^4/4 + x/16',
        'source_endpoint': str(F(2, 3)), 'source_target_offset': str(f(F(2, 3))),
        'verification_interval': ['3/4', '2'], 'center': '1', 'target': '1/16',
        'old_cube': list(map(str, Arithmetic().power(base, 3))),
        'new_cube': list(map(str, Arithmetic().power(base, 3, True))),
        'old_derivative': list(map(str, old)), 'new_derivative': list(map(str, new)),
        'exact_residual': str(f(F(1))-F(1,16)),
        'true_derivative_lower_bound_on_source_branch': str(F(1,16)-F(1,27)),
        'old_separates_derivative': old[0] > 0 or old[1] < 0,
        'new_separates_derivative': new[0] > 0 or new[1] < 0,
        'evidence': 'independent exact rational model; no package execution'
    }


# A tiny structural tree language. Head positions are index 0, as in WL.
@dataclass(frozen=True)
class Node:
    head: str
    args: tuple['Tree', ...]

Tree = Union[str, int, Node]
ELEMENT = 'System`Element'
PRIVATE_ELEMENT = 'AsymptoticAnalysis`Mathics`Element'
ASSUMPTIONS = 'System`Assumptions'


def node(head: str, *args: Tree) -> Node:
    return Node(head, tuple(args))


def protect_tree(tree: Tree, patched: bool) -> Tree:
    """Structural model of old all-occurrence vs proposed application-head map.

    It does not evaluate symbols, match arbitrary WL patterns or implement
    option parsing. An Assumptions rule is recognized exactly by its AST key.
    """
    def walk(t: Tree, in_value: bool = False) -> Tree:
        if not isinstance(t, Node):
            return PRIVATE_ELEMENT if in_value and not patched and t == ELEMENT else t
        h = t.head
        if in_value and h == ELEMENT and (not patched or len(t.args) == 2):
            h = PRIVATE_ELEMENT
        children = []
        assumption_rule = (t.head in ('Rule', 'RuleDelayed') and len(t.args) == 2
                           and t.args[0] == ASSUMPTIONS)
        for i, child in enumerate(t.args):
            children.append(walk(child, in_value or (assumption_rule and i == 1)))
        return Node(h, tuple(children))
    return walk(tree)


def context_of(symbol: str) -> str:
    return symbol.rsplit('`', 1)[0] + '`'


def assumption_program(t: Node) -> str:
    """Evaluate only the exact toy Context/If witness represented below."""
    symbol = t.args[1].args[0].args[0].args[0].args[0]
    return 'a > 0' if context_of(symbol) == 'System`' else 'a < 0'


def assumption_witness() -> Node:
    return node('Rule', ASSUMPTIONS,
                node('If', node('SameQ', node('Context', node('Unevaluated', ELEMENT)),
                                     'System`'), 'a > 0', 'a < 0'))


# Conservative positive grammar for the proposed numerical-log recovery.
# Strings represent exact named atoms; no floating sign predicate is accepted.
def positive_grammar(e: Tree | F) -> bool:
    if isinstance(e, (int, F)):
        return e > 0
    if isinstance(e, str) and e in ('Pi', 'E', 'Glaisher'):
        return True
    if isinstance(e, Node):
        if e.head == 'Times':
            return all(positive_grammar(a) for a in e.args)
        if e.head == 'Power' and len(e.args) == 2:
            return (positive_grammar(e.args[0]) and
                    isinstance(e.args[1], (int, F)))
    return False


def logarithm_witness() -> dict:
    import mpmath as mp
    from importlib.metadata import version

    def direct_q(eps_string: str, bits: int):
        with mp.workprec(bits):
            eps = mp.mpf(eps_string)
            s2 = mp.sqrt(2); s3 = mp.sqrt(3); s6 = mp.sqrt(6)
            radical = mp.sqrt(mp.fsum([mp.mpf(5), 2*s6, eps]))
            return +mp.fsum([s2, s3, -radical])

    # This policy is motivated by Mathics 10.0.1's documented source use
    # of mpmath.fsum. It is deliberately NOT labelled a Mathics evaluation.
    low = [direct_q('1e-30', 53), direct_q('1e-40', 53)]
    with mp.workprec(400):
        roots = []
        for eps in [mp.mpf('1e-30'), mp.mpf('1e-40')]:
            roots.append(-eps/(mp.sqrt(2)+mp.sqrt(3)+mp.sqrt(5+2*mp.sqrt(6)+eps)))
        third = mp.mpf('1e-20')
        direct = mp.log(roots[0]*roots[1]*third)
        split = mp.log(roots[0])+mp.log(roots[1])+mp.log(third)
        difference = split - direct
        return {
            'mpmath_version': version('mpmath'),
            'policy_model_precision_bits': 53, 'reference_precision_bits': 400,
            'epsilon_strings': ['1e-30', '1e-40'],
            'model_q_values': [mp.nstr(x, 25) for x in low],
            'model_signs': [int(mp.sign(x)) for x in low],
            'true_q_values_stable_identity': [mp.nstr(x, 60) for x in roots],
            'true_signs': [int(mp.sign(x)) for x in roots],
            'principal_log_product_imaginary_part': mp.nstr(mp.im(direct), 20),
            'sum_principal_logs_imaginary_part': mp.nstr(mp.im(split), 60),
            'difference_divided_by_2pii': mp.nstr(difference/(2*mp.pi*1j), 40),
            'evidence': '53-bit arithmetic-policy model and exact sign identity; not a Mathics or public fallback run',
            'public_Indeterminate_trigger_demonstrated': False
        }
