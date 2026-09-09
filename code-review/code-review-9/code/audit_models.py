"""Independent, exact models for the AsymptoticInverse 1.8.0 source audit.

These functions DO NOT execute or emulate all of Wolfram Language. They test
specific mathematical and resource-count arguments in the accompanying article.
Only the Python standard library is required (Python 3.10+).
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from math import comb, lcm
from typing import Iterable, Mapping

Jet = dict[F, F]
Polynomial = tuple[F, ...]  # increasing powers of L

@dataclass
class Work:
    pair_products: int = 0
    multiplication_calls: int = 0
    peak_support: int = 0


def _jet(data: Mapping[F, F]) -> Jet:
    return dict(sorted((F(w), F(c)) for w, c in data.items() if c))


def multiply(a: Mapping[F, F], b: Mapping[F, F], cutoff: F | None = None,
             work: Work | None = None, pair_limit: int | None = None) -> Jet:
    """Exact truncated multiplication; cutoff is exclusive.

    pair_limit, when present, is per multiplication, like the audited jetMul.
    This implementation is a transparent oracle, not the upstream monotone scan.
    """
    if cutoff is not None:
        cutoff = F(cutoff)
    if pair_limit is not None and pair_limit < 1:
        raise ValueError("pair_limit must be positive")
    out: Jet = {}
    pairs = 0
    if work is not None:
        work.multiplication_calls += 1
    for wa, ca in a.items():
        for wb, cb in b.items():
            w = F(wa) + F(wb)
            if cutoff is not None and w >= cutoff:
                continue
            pairs += 1
            if pair_limit is not None and pairs > pair_limit:
                raise RuntimeError("per-product pair budget exceeded")
            out[w] = out.get(w, F(0)) + F(ca) * F(cb)
    out = _jet(out)
    if work is not None:
        work.pair_products += pairs
        work.peak_support = max(work.peak_support, len(out))
    return out


def integer_power(a: Mapping[F, F], n: int, cutoff: F | None = None,
                  work: Work | None = None, pair_limit: int | None = None) -> Jet:
    """Exact finite rational-coefficient jets, including negative valuations.

    With a finite cutoff, factor out the least monomial weight alpha first.
    The normalized support is nonnegative, so truncating at cutoff-n*alpha
    during binary powering cannot lose a retained output term. This is a
    coefficient oracle only: it returns NO claim about an unknown remainder.
    """
    if not isinstance(n, int) or isinstance(n, bool) or n < 0:
        raise ValueError("n must be a nonnegative integer")
    base = _jet(a)
    if n == 0:
        return {F(0): F(1)} if cutoff is None or F(cutoff) > 0 else {}
    if not base:
        return {}
    alpha = min(base)
    shift = n * alpha
    h = None if cutoff is None else F(cutoff) - shift
    if h is not None and h <= 0:
        return {}
    base = {w - alpha: c for w, c in base.items()
            if h is None or w - alpha < h}
    result = {F(0): F(1)}
    k = n
    while k:
        if k & 1:
            result = multiply(result, base, h, work, pair_limit)
        k //= 2
        if k:
            base = multiply(base, base, h, work, pair_limit)
    return _jet({w + shift: c for w, c in result.items()})


def dense_bridge_plan(exponents: Iterable[F], remainder_power: F) -> dict[str, int]:
    """Dimension calculation only: never allocates the dense coefficient list."""
    exps = [F(w) for w in exponents]
    p = F(remainder_power)
    if any(w >= p for w in exps):
        raise ValueError("retained weights must be strictly below the remainder")
    den = lcm(*(w.denominator for w in exps + [p]))
    nmin = int((min(exps) if exps else p) * den)
    nmax = int(p * den)
    return {"sparse_blocks": len(exps), "denominator": den,
            "nmin": nmin, "nmax": nmax, "dense_slots": nmax - nmin}


def _trim(p: Iterable[F]) -> Polynomial:
    q = list(map(F, p))
    while q and not q[-1]:
        q.pop()
    return tuple(q)


def poly_add(a: Polynomial, b: Polynomial) -> Polynomial:
    return _trim((a[i] if i < len(a) else F(0)) +
                 (b[i] if i < len(b) else F(0))
                 for i in range(max(len(a), len(b))))


def poly_scale(a: Polynomial, c: F) -> Polynomial:
    return _trim(F(c) * x for x in a)


def poly_mul(a: Polynomial, b: Polynomial) -> Polynomial:
    if not a or not b:
        return ()
    q = [F(0)] * (len(a) + len(b) - 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            q[i + j] += ai * bj
    return _trim(q)


def poly_power(a: Polynomial, n: int) -> Polynomial:
    if n < 0:
        raise ValueError("nonnegative polynomial power required")
    r = (F(1),)
    for _ in range(n):
        r = poly_mul(r, a)
    return r


def poly_derivative(a: Polynomial) -> Polynomial:
    return _trim(i * a[i] for i in range(1, len(a)))


def lagrange_coefficient(k: tuple[int, ...], gaps: tuple[F, ...],
                         polynomials: tuple[Polynomial, ...], p: F = F(1),
                         r: F = F(1)) -> tuple[F, Polynomial]:
    """Euler-operator coefficient, independently implemented over Q[L]."""
    from math import factorial
    if len(k) != len(gaps) or len(k) != len(polynomials):
        raise ValueError("multi-index, gaps and polynomials must have equal lengths")
    if not p or any(not isinstance(i, int) or i < 0 for i in k):
        raise ValueError("nonzero p and nonnegative integer indices required")
    if any(F(d) <= 0 for d in gaps):
        raise ValueError("positive gaps required")
    n = sum(k)
    if n == 0:
        return F(0), (F(1),)
    weight = sum((F(d) * ki for d, ki in zip(gaps, k)), F(0))
    q = (F(1),)
    denominator = F(p) ** n
    for ki, polynomial in zip(k, polynomials):
        q = poly_mul(q, poly_power(polynomial, ki))
        denominator *= factorial(ki)
    for j in range(1, n):
        q = poly_add(poly_derivative(q), poly_scale(q, F(r) + weight + F(p) * j))
    return weight, poly_scale(q, F((-1)**n) * F(r) / denominator)


def collision_fixture(m: int = 24, denominator: int = 1000) -> dict[str, int]:
    """gaps 1+j/denominator, 1<=j<=m, retained weight <4.

    All degree<=3 indices are inside and all degree=4 indices are boundary
    when 3*(1+m/denominator)<4. Counts are exact stars-and-bars counts.
    """
    if m < 1 or denominator <= 3*m:
        raise ValueError("require m>=1 and denominator>3*m")
    inside = comb(m + 3, 3)
    boundary = comb(m + 3, 4)
    # For fixed degree n, j-sums attain every integer n,...,n*m.
    weights = 1 + sum(n * (m - 1) + 1 for n in range(1, 4))
    return {"gaps": m, "inside_indices": inside, "boundary_indices": boundary,
            "budgeted_indices": inside + boundary, "retained_weights": weights}


def product_precision(pa: F | None, pb: F | None, va: F, vb: F) -> F | None:
    """None means an exact remainder; valuations are known finite weights."""
    candidates = []
    if pa is not None:
        candidates.append(F(pa) + F(vb))
    if pb is not None:
        candidates.append(F(pb) + F(va))
    return min(candidates) if candidates else None


def required_product_precision(target: F, va: F, vb: F) -> tuple[F, F]:
    return F(target) - F(vb), F(target) - F(va)


def inverse_quadratic(order: int) -> Jet:
    """Catalan oracle for inverse of x+x^2, weights strictly below order."""
    if order < 1:
        raise ValueError("positive order required")
    return {F(n): F((-1)**(n - 1) * comb(2*n - 2, n - 1), n)
            for n in range(1, order)}
