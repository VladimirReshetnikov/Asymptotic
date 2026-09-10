"""Independent rational reference model, NOT a Wolfram/Mathics evaluator.

Orders use w=1/a -> 0+, with a >= 1. An order of None denotes an exact
zero tail. A nonzero omitted constant has order zero, regardless of cutoff.
Only positive integral Lerch s is implemented in the concrete oracle.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as Q
from math import comb, factorial
from typing import Optional


def rat(value: int | Q) -> Q:
    if isinstance(value, bool) or not isinstance(value, (int, Q)):
        raise TypeError("Exact int/Fraction required; no floating-point conversion")
    return Q(value)


def moment(z: Q, k: int) -> Q:
    """Exact geometric moment; ordinary reference utility, not a new algorithm."""
    z = rat(z)
    if abs(z) >= 1 or not isinstance(k, int) or isinstance(k, bool) or k < 0:
        raise ValueError("Require |z|<1 and a nonnegative integer degree")
    stirling = [1]
    for n in range(1, k + 1):
        prev = stirling
        stirling = [0] + [
            (prev[j - 1] if j - 1 < len(prev) else 0)
            + j * (prev[j] if j < len(prev) else 0)
            for j in range(1, n + 1)
        ]
    return sum((Q(stirling[j] * factorial(j)) * z**j / (1-z)**(j+1)
                for j in range(k+1)), Q(0))


def rising(s: int, n: int) -> int:
    value = 1
    for j in range(n):
        value *= s + j
    return value


@dataclass(frozen=True)
class Tail:
    order: Optional[int]
    constant: Q
    def __post_init__(self) -> None:
        c = rat(self.constant)
        object.__setattr__(self, 'constant', c)
        if self.order is not None and (isinstance(self.order, bool)
                                      or not isinstance(self.order, int)):
            raise TypeError("This independent model uses integral orders")
        if c < 0 or (self.order is None and c != 0):
            raise ValueError("An exact tail has zero bound; constants are nonnegative")
    def bound(self, a: Q) -> Q:
        a = rat(a)
        if a < 1:
            raise ValueError("The common-grade bound requires a>=1")
        return Q(0) if self.order is None else self.constant * a**(-self.order)


def merge_omitted_constant(tail: Tail, beta: Q) -> Tail:
    beta = rat(beta)
    if beta == 0:
        return tail
    order = 0 if tail.order is None else min(tail.order, 0)
    return Tail(order, tail.constant + abs(beta))


def split_bound(tail: Tail, beta: Q, a: Q) -> Q:
    """Sharper pointwise alternative; not the common-grade candidate patch."""
    return tail.bound(a) + abs(rat(beta))


@dataclass(frozen=True)
class LerchModel:
    z: Q
    s: int
    alpha: Q
    beta: Q
    cutoff: Q
    rows: tuple[tuple[int, Q], ...]
    charged: Q
    atom_tail: Tail
    tail: Tail
    first_moment: Optional[int]
    def normal(self, a: Q) -> Q:
        a = rat(a)
        return sum((c * a**(-p) for p,c in self.rows), Q(0))
    def source_predicted_unrepaired_bound(self, a: Q) -> Q:
        # Deliberately model the original same-grade charging operation.
        if self.atom_tail.order is None:
            raise ValueError("Infinity behavior is treated separately, not guessed")
        return (self.atom_tail.constant + abs(self.charged)) * rat(a)**(-self.atom_tail.order)


def lerch_model(z: Q, s: int, alpha: Q, beta: Q, cutoff: Q) -> LerchModel:
    z, alpha, beta, cutoff = map(rat, (z, alpha, beta, cutoff))
    if abs(z) >= 1 or not isinstance(s, int) or isinstance(s, bool) or s <= 0:
        raise ValueError("Oracle supports |z|<1 and positive integer s")
    if alpha == 0:
        raise ValueError("Nonzero affine multiplier required")
    rows = {}
    first = None
    for k in range(128):
        if z == 0 and k > 0:
            break
        c = Q((-1)**k * rising(s,k), factorial(k)) * moment(z,k)
        if c:
            if s+k >= cutoff:
                first = k
                break
            rows[s+k] = alpha*c
    else:
        raise RuntimeError("Reference expansion budget exceeded")
    atom = Tail(None, Q(0)) if first is None else Tail(
        s+first, abs(alpha) * Q(rising(s,first),factorial(first)) * moment(abs(z),first))
    charged = beta if cutoff <= 0 else Q(0)
    if cutoff > 0:
        rows[0] = rows.get(0,Q(0)) + beta
    clean = tuple(sorted((p,c) for p,c in rows.items() if c))
    return LerchModel(z,s,alpha,beta,cutoff,clean,charged,atom,
                      merge_omitted_constant(atom,charged),first)


def lerch_interval(z: Q, s: int, a: Q, terms: int = 48) -> tuple[Q,Q]:
    """Defining-sum enclosure: the geometric tail is bounded independently.

    |sum_(n=N)^infty z^n/(a+n)^s| <= |z|^N/((1-|z|)(a+N)^s).
    For z>=0 the tail is positive and the lower endpoint is the partial sum.
    """
    z,a = rat(z),rat(a)
    if abs(z) >= 1 or a <= 0 or not isinstance(s,int) or s < 1 or terms < 1:
        raise ValueError("Require |z|<1, a>0, integral s>=1, terms>=1")
    p = sum((z**n/(a+n)**s for n in range(terms)), Q(0))
    r = abs(z)**terms/((1-abs(z))*(a+terms)**s)
    return (p,p+r) if z >= 0 else (p-r,p+r)


def affine_error_interval(model: LerchModel, a: Q, terms: int = 48) -> tuple[Q,Q]:
    lo,hi = lerch_interval(model.z,model.s,a,terms)
    vals = sorted((model.alpha*lo, model.alpha*hi))
    return tuple(v + model.beta - model.normal(a) for v in vals)
