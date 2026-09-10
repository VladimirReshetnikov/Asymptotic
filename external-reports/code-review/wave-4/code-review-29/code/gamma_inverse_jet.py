"""Exact finite Stirling-inverse jets, independently implemented for this audit.

The coefficient ring is Q[a,q], a=(1-log(2*pi)*q)/2. The routines solve the
finite formal equation in the article; they do NOT certify an original Gamma
inverse, implement the repository's GeneralizedSeries contract, or run Mathics.
Requires SymPy. Precision n below means coefficients of t^0 through t^(n-1).
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from sympy import bernoulli
from sympy.polys.domains import QQ
from sympy.polys.rings import ring

R, a, q = ring('a,q', QQ)
ZERO, ONE = R.zero, R.one

@dataclass
class Statistics:
    coefficient_multiplications: int = 0
    nonlinear_evaluations: int = 0
    newton_stages: int = 0

class JetAlgebra:
    def __init__(self, statistics: Statistics | None = None):
        self.statistics = statistics or Statistics()

    @staticmethod
    def zero(n): return [ZERO for _ in range(n)]
    @staticmethod
    def identity(n): return [ONE] + [ZERO for _ in range(n-1)]
    @staticmethod
    def pad(v, n): return list(v[:n]) + [ZERO for _ in range(max(0, n-len(v)))]
    def add(self, x, y, n):
        x, y = self.pad(x,n), self.pad(y,n)
        return [x[i]+y[i] for i in range(n)]
    def scale(self, x, c, n): return [v*c for v in self.pad(x,n)]
    def shift(self, x, k, n):
        return [ZERO]*min(k,n) + self.pad(x, max(0,n-k))
    def mul(self, x, y, n):
        out = self.zero(n)
        for i, xi in enumerate(x[:n]):
            if not xi: continue
            for j, yj in enumerate(y[:n-i]):
                if not yj: continue
                self.statistics.coefficient_multiplications += 1
                out[i+j] += xi*yj
        return out
    def inverse(self, x, n):
        x = self.pad(x,n)
        if x[0] != ONE: raise ValueError('Only units with constant coefficient one are admitted')
        out = self.identity(n)
        for k in range(1,n):
            v = ZERO
            for i in range(1,k+1):
                if x[i] and out[k-i]:
                    self.statistics.coefficient_multiplications += 1
                    v += x[i]*out[k-i]
            out[k] = -v
        return out
    def log_unit(self, x, n):
        x = self.pad(x,n)
        if x[0] != ONE: raise ValueError('log requires a unit with constant term one')
        derivative = [x[i]*i for i in range(1,n)]
        ratio = self.mul(derivative, self.inverse(x,n), max(0,n-1))
        return [ZERO] + [ratio[i-1]*QQ(1,i) for i in range(1,n)]

    def phase(self, u, n, with_derivative=False):
        """Phi(u) and optionally dPhi/du, truncated to n coefficients."""
        self.statistics.nonlinear_evaluations += 1
        u = self.pad(u,n)
        A = self.add(self.identity(n),u,n)
        L = self.log_unit(A,n)
        V = self.inverse(A,n)
        F = self.add(u, self.scale(self.add(self.mul(A,L,n),self.scale(u,-ONE,n),n),q,n),n)
        if n > 1: F[1] -= a
        F = self.add(F,self.scale(self.shift(L,1,n),-q*QQ(1,2),n),n)
        D = self.add(self.identity(n),self.scale(L,q,n),n) if with_derivative else None
        if with_derivative:
            D = self.add(D,self.scale(self.shift(V,1,n),-q*QQ(1,2),n),n)
        # Reuse inverse-unit powers instead of rebuilding each negative power.
        V2 = self.mul(V,V,n)
        odd, even = V, V2
        for k in range(1,(n-1)//2+1):
            B = bernoulli(2*k)
            b = QQ(int(B.p),int(B.q))
            F = self.add(F,self.scale(self.shift(odd,2*k,n),q*b/QQ(2*k*(2*k-1)),n),n)
            if with_derivative:
                D = self.add(D,self.scale(self.shift(even,2*k,n),-q*b/QQ(2*k),n),n)
            remaining = n-2*(k+1)
            if remaining > 0:
                odd = self.mul(odd,V2,remaining)
                if with_derivative: even = self.mul(even,V2,remaining)
        return F, D


def validate_order(order: int) -> None:
    if isinstance(order,bool) or not isinstance(order,int) or not 0 <= order <= 24:
        raise ValueError('order must be an integer from 0 to 24; prototype resource cap')


def triangular(order: int):
    """Coefficient-by-coefficient construction reflecting the source recurrence."""
    validate_order(order)
    alg = JetAlgebra()
    u = alg.zero(order+1)
    for j in range(1,order+1):
        F,_ = alg.phase(u,j+1)
        u[j] = -F[j]
    return u, alg.statistics


def newton(order: int):
    """Precision-doubling formal Newton; exact arithmetic in Q[a,q][[t]]."""
    validate_order(order)
    alg = JetAlgebra()
    u, precision = [ZERO], 1
    while precision < order+1:
        target = min(2*precision,order+1)
        F,D = alg.phase(u,target,with_derivative=True)
        correction = alg.mul(F,alg.inverse(D,target),target)
        u = alg.add(u,alg.scale(correction,-ONE,target),target)
        precision = target
        alg.statistics.newton_stages += 1
    return u, alg.statistics


def evaluate_polynomial(poly, av, qv, context):
    total = context.mpf(0)
    for (ia,iq), coefficient in poly.items():
        total += (context.mpf(int(coefficient.numerator))/int(coefficient.denominator)
                  * av**ia * qv**iq)
    return total


def evaluate_gamma_inverse(core, coefficients, context):
    """Approximate x with log Gamma(x)=core*(log(core)-1), for large real core."""
    z = context.mpf(core)
    if z <= 1: raise ValueError('core must exceed one')
    qv = 1/context.log(z)
    av = (1-context.log(2*context.pi)*qv)/2
    u = sum(evaluate_polynomial(p,av,qv,context)/z**j
            for j,p in enumerate(coefficients))
    return z*(1+u)
