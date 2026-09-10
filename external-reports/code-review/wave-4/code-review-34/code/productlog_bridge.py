"""Candidate Mathics ProductLog conversion methods, independently testable.

The mixin is not installed automatically. Its methods require integration
into Mathics3's ProductLog class and a real Mathics regression run before use.
"""
from __future__ import annotations
import mpmath


class ProductLogOrderMixin:
    nargs = {1, 2}

    def prepare_sympy(self, elements):
        elements = tuple(elements)
        return (elements[1], elements[0]) if len(elements) == 2 else elements

    def from_sympy(self, elements):
        elements = tuple(elements)
        reordered = (elements[1], elements[0]) if len(elements) == 2 else elements
        return super().from_sympy(reordered)

    def get_mpmath_function(self, args):
        if len(args) == 1:
            return mpmath.lambertw
        if len(args) == 2:
            return lambda branch, argument: mpmath.lambertw(argument, branch)
        return None
