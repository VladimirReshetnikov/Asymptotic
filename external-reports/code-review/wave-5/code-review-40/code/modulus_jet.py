"""Exact, log-free modulus jets (research reference implementation).

Input: integer powers of a positive real u, Gaussian-rational coefficients,
and an optional magnitude-remainder power P. No derivative contract is inferred.
This is not a Wolfram Language package or an execution of AsymptoticAnalysis.
"""
from __future__ import annotations
from dataclasses import dataclass
from typing import Mapping
import sympy as sp

@dataclass(frozen=True)
class ModulusJet:
    rows: tuple[tuple[int, sp.Expr], ...]
    error_power: int
    derivative_order: int = 0

    def expression(self, variable: sp.Symbol) -> sp.Expr:
        return sp.Add(*(c * variable**k for k, c in self.rows))


def modulus_jet(coefficients: Mapping[int, sp.Expr], cutoff: int, *,
                input_error_power: int | None = None,
                max_order: int = 512, max_pairs: int = 100_000) -> ModulusJet:
    """Return |sum c[k] u**k + O(u**P)| through powers strictly below cutoff.

    None for input_error_power means an exact finite input polynomial/Laurent
    polynomial, NOT exactness of its modulus. The output deliberately retains
    a conservative magnitude remainder even when exact termination is possible.
    All arguments are validated; no floating-point constants are accepted.
    """
    for name, value in (("cutoff", cutoff), ("max_order", max_order),
                        ("max_pairs", max_pairs)):
        if type(value) is not int:
            raise TypeError(f"{name} must be an integer")
    if max_order < 1 or max_pairs < 1:
        raise ValueError("budgets must be positive")
    if input_error_power is not None and type(input_error_power) is not int:
        raise TypeError("input_error_power must be an integer or None")
    rows: dict[int, sp.Expr] = {}
    for k, value in coefficients.items():
        if type(k) is not int:
            raise TypeError("weights must be integers")
        value = sp.sympify(value)
        re, im = sp.expand_complex(value).as_real_imag()
        if not (re.is_Rational and im.is_Rational):
            raise ValueError("coefficients must be exact Gaussian rationals")
        if value == 0:
            continue
        if input_error_power is not None and k >= input_error_power:
            raise ValueError("all retained powers must precede the input remainder")
        rows[k] = sp.expand(value)
    if not rows:
        return ModulusJet((), min(cutoff, input_error_power)
                          if input_error_power is not None else cutoff)
    alpha = min(rows)
    h = min(cutoff, input_error_power) if input_error_power is not None else cutoff
    if h <= alpha:
        return ModulusJet((), alpha)
    depth = h - alpha
    if depth > max_order:
        raise ValueError("relative Taylor depth exceeds max_order")
    active = sorted((k - alpha, c) for k, c in rows.items() if k < h)
    q = [sp.S.Zero] * depth
    count = 0
    for i, ci in active:
        for j, cj in active:
            if i + j >= depth:
                break
            count += 1
            if count > max_pairs:
                raise ValueError("retained convolution pairs exceed max_pairs")
            q[i + j] += ci * sp.conjugate(cj)
    q = [sp.expand(value) for value in q]
    if q[0].is_positive is not True:
        raise ValueError("nonzero positive leading squared modulus required")
    root = [sp.sqrt(q[0])]
    for k in range(1, depth):
        known = sum((root[i] * root[k - i] for i in range(1, k)), sp.S.Zero)
        root.append(sp.simplify((q[k] - known) / (2 * root[0])))
    result = tuple((alpha + k, c) for k, c in enumerate(root) if c != 0)
    return ModulusJet(result, h)
