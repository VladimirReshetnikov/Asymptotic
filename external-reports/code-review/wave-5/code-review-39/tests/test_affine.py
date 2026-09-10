from fractions import Fraction as Q
import random
import pytest
from affine_model import (X, add, mul, rational, horner, tree_size, round_q,
                          enclose_old, enclose_cached, evaluate_exact)

@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64])
def test_exact_quadratic_visit_count(n):
    e = horner(n)
    old = dict(affine_visits=0, enclosure_visits=0)
    new = dict(classification_visits=0, enclosure_visits=0)
    a = enclose_old(e, (Q(1,4), Q(1,2)), 32, old)
    b = enclose_cached(e, (Q(1,4), Q(1,2)), 32, new)
    assert tree_size(e) == 4*n+1
    assert old["affine_visits"] == 4*n*(n+1)
    assert new["classification_visits"] <= 4*n+1
    assert a == b

@pytest.mark.parametrize("bits", [2, 8, 32])
def test_huge_affine_translation_is_not_regressed(bits):
    a = Q(2**10000 + 1)
    e = add(X, rational(-a))
    old = dict(affine_visits=0, enclosure_visits=0)
    new = dict(classification_visits=0, enclosure_visits=0)
    assert enclose_old(e, (a, a), bits, old) == (0,0)
    assert enclose_cached(e, (a, a), bits, new) == (0,0)

@pytest.mark.parametrize("bits", [2, 4, 16])
def test_rounding_contains_exact_rationals(bits):
    for numerator in range(-35, 36):
        for denominator in range(1, 15):
            q = Q(numerator, denominator)
            assert round_q(q, bits, False) <= q <= round_q(q, bits, True)

def test_seeded_random_trees_preserve_all_endpoints():
    rng = random.Random(6512029)
    def tree(depth):
        if depth == 0 or rng.random() < .25:
            return X if rng.random() < .5 else rational(Q(rng.randint(-9,9), rng.randint(1,7)))
        op = add if rng.random() < .5 else mul
        return op(tree(depth-1), tree(depth-1))
    for _ in range(120):
        e = tree(5)
        bits = rng.choice([2,8,32])
        interval = (Q(-3,4), Q(5,4))
        old = dict(affine_visits=0, enclosure_visits=0)
        new = dict(classification_visits=0, enclosure_visits=0)
        a = enclose_old(e, interval, bits, old)
        b = enclose_cached(e, interval, bits, new)
        assert a == b
        for x in [interval[0], Q(0), interval[1]]:
            y = evaluate_exact(e,x)
            assert a[0] <= y <= a[1]
