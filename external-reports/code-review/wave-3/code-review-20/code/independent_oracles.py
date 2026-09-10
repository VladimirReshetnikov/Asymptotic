#!/usr/bin/env python3
"""Exact Q(sqrt(2)) oracles for the article's forward/inverse example.

Python standard library only. No upstream algorithm or Wolfram kernel is used.
The general inverse coefficients are checked by formal implicit substitution.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from math import factorial
import unittest

@dataclass(frozen=True)
class Q2:
    a: F = F(0)
    b: F = F(0)
    def __post_init__(self):
        object.__setattr__(self, 'a', F(self.a))
        object.__setattr__(self, 'b', F(self.b))
    @staticmethod
    def coerce(x):
        return x if isinstance(x, Q2) else Q2(F(x))
    def __add__(self, other):
        t = self.coerce(other)
        return Q2(self.a+t.a, self.b+t.b)
    __radd__ = __add__
    def __neg__(self):
        return Q2(-self.a, -self.b)
    def __sub__(self, other):
        return self + -self.coerce(other)
    def __rsub__(self, other):
        return self.coerce(other) + -self
    def __mul__(self, other):
        t = self.coerce(other)
        return Q2(self.a*t.a+2*self.b*t.b, self.a*t.b+self.b*t.a)
    __rmul__ = __mul__
    def __truediv__(self, other):
        t = self.coerce(other)
        d = t.a*t.a-2*t.b*t.b
        if not d:
            raise ZeroDivisionError('zero element of Q(sqrt(2))')
        return self * Q2(t.a/d, -t.b/d)
    def sign(self):
        if not self.b:
            return (self.a > 0)-(self.a < 0)
        if not self.a:
            return (self.b > 0)-(self.b < 0)
        if self.a > 0 and self.b > 0:
            return 1
        if self.a < 0 and self.b < 0:
            return -1
        d = self.a*self.a - 2*self.b*self.b
        s = (d > 0)-(d < 0)
        return s if self.a > 0 else -s

ZERO, ONE, SQRT2 = Q2(), Q2(1), Q2(0,1)

def mul(p: list[Q2], q: list[Q2], n: int) -> list[Q2]:
    out = [ZERO]*(n+1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            if i+j <= n:
                out[i+j] = out[i+j] + a*b
    return out

def coefficient(r: Q2, k: int) -> Q2:
    if k == 0:
        return ONE
    value = Q2((-1)**k)
    for j in range(k-1):
        value = value*(k*r-j)
    return value/factorial(k)

def residual(r: Q2, n: int) -> list[Q2]:
    u = [coefficient(r,k) for k in range(n+1)]
    v = u.copy()
    v[0] = ZERO
    power = [ONE]+[ZERO]*n
    raised = [ZERO]*(n+1)
    choose = ONE
    for j in range(n+1):
        raised = [a+choose*b for a,b in zip(raised,power)]
        power = mul(power,v,n)
        choose = choose*(r-j)/(j+1)
    # U + epsilon U^r - 1, modulo epsilon^(n+1).
    return [u[0]-ONE]+[u[k]+raised[k-1] for k in range(1,n+1)]

class ExactOracles(unittest.TestCase):
    def test_inverse_implicit_identity(self):
        for r in [Q2(F(3,2)), Q2(2), Q2(3), SQRT2]:
            with self.subTest(r=r):
                self.assertEqual(residual(r,8), [ZERO]*9)
    def test_observed_native_package_coefficients(self):
        expected = [ONE,Q2(-1),SQRT2,Q2(-3,F(1,2)),Q2(-4,F(17,3))]
        self.assertEqual([coefficient(SQRT2,k) for k in range(5)], expected)
    def test_forward_support(self):
        actual = {(j,k):F(1,factorial(j)*factorial(k))
                  for j in range(4) for k in range(4)
                  if (Q2(j,k)-3).sign() < 0}
        expected = {(0,0):F(1),(1,0):F(1),(0,1):F(1),
                    (2,0):F(1,2),(1,1):F(1),(0,2):F(1,2)}
        self.assertEqual(actual,expected)
    def test_inverse_frontier(self):
        self.assertLess((Q2(-3,4)-3).sign(),0)
        self.assertGreater((Q2(-4,5)-3).sign(),0)
    def test_exact_field_order(self):
        self.assertEqual(Q2(-2,1).sign(),-1)
        self.assertEqual(Q2(-1,1).sign(),1)
        self.assertEqual(Q2(1,-1).sign(),-1)
        self.assertEqual(Q2(2,-1).sign(),1)
        self.assertEqual(Q2().sign(),0)
    def test_regular_inverse_control(self):
        self.assertEqual([coefficient(Q2(2),k) for k in range(5)],
                         list(map(Q2,[1,-1,2,-5,14])))

if __name__ == '__main__':
    unittest.main(verbosity=2)
