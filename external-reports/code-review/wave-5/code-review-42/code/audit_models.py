"""Independent mathematical/structural models, NOT a Wolfram evaluator.

These algorithms expose the three audit proof obligations without importing
AsymptoticAnalysis. Counts are model counts, not native kernel benchmarks.
Python 3.10+, standard library only.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as Q
from typing import Optional

Pair = tuple[Q, Q]
Interval = tuple[Q, Q]

@dataclass(frozen=True)
class Node:
    kind: str
    children: tuple['Node', ...] = ()
    value: Optional[Q] = None

X = Node('x')
def rat(n: int | Q) -> Node: return Node('q', value=Q(n))
def add(*args: Node) -> Node: return Node('add', args)
def mul(*args: Node) -> Node: return Node('mul', args)
def square(arg: Node) -> Node: return Node('power', (arg, rat(2)))

def horner(depth: int) -> Node:
    if depth < 0: raise ValueError('depth must be nonnegative')
    e = add(rat(1), square(X))
    for _ in range(depth): e = add(rat(1), mul(X, e))
    return e

@dataclass
class Counts:
    probes: int = 0
    annotations: int = 0
    enclosures: int = 0

def combine(kind: str, pairs: tuple[Optional[Pair], ...]) -> Optional[Pair]:
    if any(p is None for p in pairs): return None
    if kind == 'add':
        return (sum((p[0] for p in pairs), Q(0)),
                sum((p[1] for p in pairs), Q(0)))
    if kind == 'mul':
        a, b = Q(0), Q(1)
        for c, d in pairs:
            if a*c != 0: return None
            a, b = a*d+b*c, b*d
        return a, b
    return None

def affine_pair(e: Node, count: Counts) -> Optional[Pair]:
    """Mirrors the inspected recognizer's recursive control structure."""
    count.probes += 1
    if e.kind == 'x': return Q(1), Q(0)
    if e.kind == 'q': return Q(0), e.value
    if e.kind in ('add', 'mul'):
        return combine(e.kind, tuple(affine_pair(c, count) for c in e.children))
    return None

def affine_range(p: Pair, interval: Interval) -> Interval:
    a, b = p
    return tuple(sorted((a*interval[0]+b, a*interval[1]+b)))

def plus_range(parts: tuple[Interval, ...]) -> Interval:
    return sum((p[0] for p in parts), Q(0)), sum((p[1] for p in parts), Q(0))

def times_range(parts: tuple[Interval, ...]) -> Interval:
    out = (Q(1), Q(1))
    for p in parts:
        products = tuple(a*b for a in out for b in p)
        out = min(products), max(products)
    return out

def square_range(p: Interval) -> Interval:
    hi = max(p[0]*p[0], p[1]*p[1])
    lo = Q(0) if p[0] <= 0 <= p[1] else min(p[0]*p[0], p[1]*p[1])
    return lo, hi

def enclose_reprobing(e: Node, interval: Interval, count: Counts) -> Interval:
    """Exact-rational arithmetic only; no native dyadic-rounding emulation."""
    count.enclosures += 1
    if e.kind == 'x': return interval
    if e.kind == 'q': return e.value, e.value
    if e.kind in ('add', 'mul'):
        p = affine_pair(e, count)
        if p is not None: return affine_range(p, interval)
        parts = tuple(enclose_reprobing(c, interval, count) for c in e.children)
        return plus_range(parts) if e.kind == 'add' else times_range(parts)
    if e.kind == 'power' and e.children[1] == rat(2):
        return square_range(enclose_reprobing(e.children[0], interval, count))
    raise ValueError(f'Unsupported model syntax: {e.kind}')

@dataclass(frozen=True)
class Annotated:
    node: Node
    pair: Optional[Pair]
    children: tuple['Annotated', ...]

def annotate(e: Node, count: Counts) -> Annotated:
    """One bottom-up pass; unsupported affine heads can contain useful children."""
    count.annotations += 1
    children = tuple(annotate(c, count) for c in e.children)
    p = ((Q(1), Q(0)) if e.kind == 'x' else
         (Q(0), e.value) if e.kind == 'q' else
         combine(e.kind, tuple(c.pair for c in children)))
    return Annotated(e, p, children)

def enclose_annotated(a: Annotated, interval: Interval, count: Counts) -> Interval:
    count.enclosures += 1
    if a.pair is not None: return affine_range(a.pair, interval)
    if a.node.kind in ('add', 'mul'):
        parts = tuple(enclose_annotated(c, interval, count) for c in a.children)
        return plus_range(parts) if a.node.kind == 'add' else times_range(parts)
    if a.node.kind == 'power' and a.node.children[1] == rat(2):
        return square_range(enclose_annotated(a.children[0], interval, count))
    raise ValueError(f'Unsupported model syntax: {a.node.kind}')

def evaluate(e: Node, x: Q) -> Q:
    if e.kind == 'x': return x
    if e.kind == 'q': return e.value
    if e.kind == 'add': return sum((evaluate(c, x) for c in e.children), Q(0))
    if e.kind == 'mul':
        out = Q(1)
        for c in e.children: out *= evaluate(c, x)
        return out
    if e.kind == 'power' and e.children[1] == rat(2):
        return evaluate(e.children[0], x)**2
    raise ValueError(e.kind)

@dataclass
class MembershipCounts:
    comparisons: int = 0

def old_removed(before: list, after: list, count: MembershipCounts) -> list:
    """Linear-search model of the repeated membership expression.
    Does not model undocumented internals of Wolfram MemberQ/SubsetQ.
    """
    removed = []
    for row in before:
        found = False
        for kept in after:
            count.comparisons += 1
            if row == kept:
                found = True
                break
        if not found: removed.append(row)
    if not all(row in before for row in after):
        raise ValueError('after is not a subset of before')
    return removed

def prefix_removed(before: list, after: list, count: MembershipCounts) -> list:
    """Fast prefix path, with the old behavior as a general fallback."""
    prefix = len(after) <= len(before)
    if prefix:
        for i, row in enumerate(after):
            count.comparisons += 1
            if before[i] != row:
                prefix = False
                break
    if prefix: return before[len(after):]
    return old_removed(before, after, count)

def derivative_coefficients(m: int, a: int, b: int, order: int) -> tuple[int,int,int]:
    """D^k[y^m(a sin(log y)+b cos(log y))] exactly, as (power,a,b)."""
    if order < 0: raise ValueError('order must be nonnegative')
    for _ in range(order):
        a, b = m*a-b, a+m*b
        m -= 1
    return m, a, b
