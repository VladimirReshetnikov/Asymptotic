"""Independent exact model of the new affine-recognition/enclosure control flow.

The supported grammar is deliberately limited to rational constants, one
variable, Plus and Times. This is not the package or its full certificate engine.
It reproduces dyadic outward rounding and compares old speculative traversal
against a two-pass, identity-keyed, request-local classification cache.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as Q
from itertools import product
from typing import Optional

Interval = tuple[Q, Q]
Pair = Optional[tuple[Q, Q]]

@dataclass(frozen=True, eq=False)
class Node:
    op: str
    args: tuple["Node", ...] = ()
    value: Q = Q(0)

X = Node("x")

def rational(value=0) -> Node:
    return Node("q", value=Q(value))

def add(*args: Node) -> Node:
    return Node("add", tuple(args))

def mul(*args: Node) -> Node:
    return Node("mul", tuple(args))

def horner(n: int) -> Node:
    if not isinstance(n, int) or isinstance(n, bool) or n < 0:
        raise ValueError("n must be a nonnegative integer")
    e = X
    for _ in range(n):
        e = mul(X, add(rational(1), e))
    return e

def tree_size(e: Node) -> int:
    return 1 + sum(tree_size(c) for c in e.args)

def round_q(q: Q, bits: int, upper: bool) -> Q:
    if bits < 1:
        raise ValueError("bits must be positive")
    if not q:
        return Q(0)
    a = abs(q)
    exponent = a.numerator.bit_length() - a.denominator.bit_length()
    power = Q(2) ** exponent
    if a < power:
        exponent -= 1
    grid = Q(2) ** (exponent - bits + 1)
    scaled = q / grid
    integer = (-((-scaled.numerator) // scaled.denominator) if upper
               else scaled.numerator // scaled.denominator)
    return grid * integer

def rounded(i: Interval, bits: int) -> Interval:
    return round_q(i[0], bits, False), round_q(i[1], bits, True)

def plus_i(a: Interval, b: Interval, bits: int) -> Interval:
    return rounded((a[0] + b[0], a[1] + b[1]), bits)

def times_i(a: Interval, b: Interval, bits: int) -> Interval:
    p = [x * y for x, y in product(a, b)]
    return rounded((min(p), max(p)), bits)

def combine_pair(op: str, pairs: list[Pair]) -> Pair:
    if any(p is None for p in pairs):
        return None
    good = [p for p in pairs if p is not None]
    if op == "add":
        return sum((p[0] for p in good), Q(0)), sum((p[1] for p in good), Q(0))
    if op == "mul":
        a, b = Q(0), Q(1)
        for c, d in good:
            if a * c != 0:
                return None
            a, b = a * d + b * c, b * d
        return a, b
    return None

def affine_pair(e: Node, count: dict) -> Pair:
    count["affine_visits"] += 1
    if e.op == "x":
        return Q(1), Q(0)
    if e.op == "q":
        return Q(0), e.value
    if e.op in {"add", "mul"}:
        return combine_pair(e.op, [affine_pair(c, count) for c in e.args])
    return None

def affine_range(pair: tuple[Q, Q], interval: Interval, bits: int) -> Interval:
    a, b = pair
    values = [a * x + b for x in interval]
    return rounded((min(values), max(values)), bits)

def _fold_intervals(op: str, values: list[Interval], bits: int) -> Interval:
    out = (Q(0), Q(0)) if op == "add" else (Q(1), Q(1))
    operation = plus_i if op == "add" else times_i
    for value in values:
        out = operation(out, value, bits)
    return out

def enclose_old(e: Node, interval: Interval, bits: int, count: dict) -> Interval:
    count["enclosure_visits"] += 1
    if e.op == "x":
        return interval
    if e.op == "q":
        return e.value, e.value
    if e.op not in {"add", "mul"}:
        raise ValueError("Unsupported grammar")
    pair = affine_pair(e, count)
    if pair is not None:
        return affine_range(pair, interval, bits)
    return _fold_intervals(e.op, [enclose_old(c, interval, bits, count) for c in e.args], bits)

def enclose_cached(e: Node, interval: Interval, bits: int, count: dict) -> Interval:
    # Node identity is valid only within this call and does not recursively
    # hash a whole subtree. Nothing is retained after the request returns.
    cache: dict[int, Pair] = {}
    def classify(node: Node) -> Pair:
        key = id(node)
        if key in cache:
            return cache[key]
        count["classification_visits"] += 1
        if node.op == "x":
            value = (Q(1), Q(0))
        elif node.op == "q":
            value = (Q(0), node.value)
        elif node.op in {"add", "mul"}:
            value = combine_pair(node.op, [classify(c) for c in node.args])
        else:
            value = None
        cache[key] = value
        return value
    classify(e)
    def evaluate(node: Node) -> Interval:
        count["enclosure_visits"] += 1
        if node.op == "x":
            return interval
        if node.op == "q":
            return node.value, node.value
        if node.op not in {"add", "mul"}:
            raise ValueError("Unsupported grammar")
        pair = cache[id(node)]
        if pair is not None:
            return affine_range(pair, interval, bits)
        return _fold_intervals(node.op, [evaluate(c) for c in node.args], bits)
    return evaluate(e)

def evaluate_exact(e: Node, x: Q) -> Q:
    if e.op == "x":
        return x
    if e.op == "q":
        return e.value
    values = [evaluate_exact(c, x) for c in e.args]
    if e.op == "add":
        return sum(values, Q(0))
    if e.op == "mul":
        out = Q(1)
        for value in values:
            out *= value
        return out
    raise ValueError("Unsupported grammar")
