#!/usr/bin/env python3
"""Independent mathematical checks for PowerLogInverse.

This is not a Wolfram Language interpreter and does NOT execute the .wl file.
It checks the coefficient theorem with a separate truncated multivariate-jet
algebra, direct differentiation, known algebraic inverses, and 100-digit
numerics. The JSON/text reports state this distinction explicitly.

Requirements: Python 3.10+, sympy, mpmath. Run: python Verification/verify.py
SPDX-License-Identifier: MIT
"""
from __future__ import annotations
import json
import math
import platform
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
import sympy as sp
import mpmath as mp

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
L = sp.Symbol('L', real=True)
y = sp.Symbol('y', positive=True)
RESULTS: list[dict] = []


def check(name: str, condition: bool, detail: str = '') -> None:
    passed = bool(condition)
    RESULTS.append({'name': name, 'passed': passed, 'detail': detail})
    if not passed:
        raise AssertionError(name + ': ' + detail)


def indices(m: int, n: int) -> Iterable[tuple[int, ...]]:
    """All nonnegative integer m-tuples of total degree at most n."""
    if m == 0:
        yield ()
    else:
        for j in range(n + 1):
            for tail in indices(m - 1, n - j):
                yield (j,) + tail


def coeff(p, gaps, polys, k, q=1):
    """Euler-polynomial version of the proved coefficient formula."""
    p, q = sp.sympify(p), sp.sympify(q)
    n = sum(k)
    if n == 0:
        return sp.S.One
    delta = sp.expand(sum((ki*di for ki, di in zip(k, gaps)), sp.S.Zero))
    z = sp.expand(sp.prod(P**ki for P, ki in zip(polys, k)))
    for r in range(1, n):
        z = sp.expand((q + delta + p*r)*z + sp.diff(z, L))
    return sp.expand((-1)**n * q * z / (p**n * sp.prod(sp.factorial(ki) for ki in k)))


@dataclass
class Jet:
    """Independent finite ordinary multivariate series algebra.

    Keys are marker exponents, NOT the real asymptotic exponents. All operations
    below are ordinary finite polynomial operations and binomial/log Taylor
    identities. No inverse-coefficient theorem is used in Picard iteration.
    """
    m: int
    n: int
    c: dict[tuple[int, ...], sp.Expr]

    def __post_init__(self):
        self.c = {k: sp.expand(v) for k, v in self.c.items()
                  if sum(k) <= self.n and v != 0}
        self.c = {k: v for k, v in self.c.items() if v != 0}

    @classmethod
    def scalar(cls, m, n, a):
        return cls(m, n, {(0,)*m: sp.sympify(a)})

    def coerce(self, other):
        if isinstance(other, Jet):
            if (self.m, self.n) != (other.m, other.n):
                raise ValueError('incompatible jets')
            return other
        return Jet.scalar(self.m, self.n, other)

    def __add__(self, other):
        other = self.coerce(other)
        out = self.c.copy()
        for k, v in other.c.items():
            out[k] = out.get(k, 0) + v
        return Jet(self.m, self.n, out)

    __radd__ = __add__

    def __neg__(self):
        return Jet(self.m, self.n, {k: -v for k, v in self.c.items()})

    def __sub__(self, other):
        return self + (-self.coerce(other))

    def __mul__(self, other):
        other = self.coerce(other)
        out = {}
        for k, a in self.c.items():
            for j, b in other.c.items():
                h = tuple(x+z for x, z in zip(k, j))
                if sum(h) <= self.n:
                    out[h] = out.get(h, 0) + a*b
        return Jet(self.m, self.n, out)

    __rmul__ = __mul__

    def shift(self, j):
        out = {}
        for k, v in self.c.items():
            h = list(k)
            h[j] += 1
            if sum(h) <= self.n:
                out[tuple(h)] = v
        return Jet(self.m, self.n, out)

    def power(self, alpha):
        """Binomial series about constant term one."""
        if self.c.get((0,)*self.m, 0) != 1:
            raise ValueError('power requires constant term 1')
        alpha = sp.sympify(alpha)
        h = self - 1
        result = Jet.scalar(self.m, self.n, 1)
        term = Jet.scalar(self.m, self.n, 1)
        factor = sp.S.One
        for r in range(1, self.n+1):
            term = term*h
            factor = sp.expand(factor*(alpha-r+1)/r)
            result = result + factor*term
        return result

    def log(self):
        if self.c.get((0,)*self.m, 0) != 1:
            raise ValueError('log requires constant term 1')
        h = self-1
        result = Jet.scalar(self.m, self.n, 0)
        term = Jet.scalar(self.m, self.n, 1)
        for r in range(1, self.n+1):
            term = term*h
            result = result + sp.Rational((-1)**(r+1), r)*term
        return result

    def polynomial(self, polynomial):
        """Evaluate a polynomial in L at this jet, by Horner's rule."""
        out = Jet.scalar(self.m, self.n, 0)
        for a in sp.Poly(polynomial, L).all_coeffs():
            out = out*self + a
        return out

    def equals(self, other):
        difference = self-self.coerce(other)
        return all(sp.simplify(v) == 0 for v in difference.c.values())


def perturbation(u: Jet, gaps, polys):
    logu = L + u.log()
    out = Jet.scalar(u.m, u.n, 0)
    for j, (delta, P) in enumerate(zip(gaps, polys)):
        out = out + (u.power(delta)*logu.polynomial(P)).shift(j)
    return out


def picard(p, gaps, polys, n):
    """Solve u=(1+R(u))^(-1/p), in independent markers, by iteration."""
    u = Jet.scalar(len(gaps), n, 1)
    for _ in range(n):
        u = (1 + perturbation(u, gaps, polys)).power(-1/sp.sympify(p))
    return u


def theorem_jet(p, gaps, polys, n, q=1):
    return Jet(len(gaps), n,
               {k: coeff(p, gaps, polys, k, q) for k in indices(len(gaps), n)})


def positive(expr):
    value = sp.simplify(expr)
    if value.is_positive is None:
        raise ValueError(f'undecidable exact comparison: {value}')
    return bool(value.is_positive)


def less(a, b):
    return positive(sp.sympify(b)-sp.sympify(a))


def weight(k, gaps):
    return sp.simplify(sum((ki*di for ki, di in zip(k, gaps)), sp.S.Zero))


def weighted_bfs(gaps, cutoff):
    origin = (0,)*len(gaps)
    queue, seen, included, boundary = deque([origin]), {origin}, [origin], []
    while queue:
        k = queue.popleft()
        for j in range(len(gaps)):
            h = list(k)
            h[j] += 1
            h = tuple(h)
            if h not in seen:
                seen.add(h)
                if less(weight(h, gaps), cutoff):
                    queue.append(h)
                    included.append(h)
                else:
                    boundary.append(h)
    return included, boundary


def symbolic_tests():
    alpha = sp.Symbol('alpha', positive=True)
    for n in range(1, 11):
        direct = sp.expand((-1)**n/sp.factorial(n) *
                           sp.diff((y*y*(1+sp.log(y)))**n, y, n-1) /
                           y**(n+1))
        direct = sp.expand(direct.subs(sp.log(y), L))
        check(f'log/direct-derivative/n={n}',
              sp.simplify(direct-coeff(1,[1],[1+L],(n,))) == 0)
        pure = (-1)**n/sp.factorial(n)*sp.prod(n*alpha-r for r in range(n-1))
        check(f'power/falling-factorial/n={n}',
              sp.simplify(pure-coeff(1,[alpha-1],[1],(n,))) == 0)
        lead = sp.Poly(coeff(1,[1],[1+L],(n,)),L).LC()
        check(f'log/Catalan-leading-coefficient/n={n}', lead == (-1)**n*sp.catalan(n))

    cases = [
        ('log', 1, [1], [1+L], 7, 1),
        ('sqrt2', 1, [sp.sqrt(2)-1], [1], 8, 1),
        ('mixed-rational-log', sp.Rational(3,2), [sp.Rational(1,2),1],
         [1+L,2-L], 4, 1),
        ('mixed-irrational', 1, [sp.sqrt(2)-1,sp.sqrt(3)-1], [1,2], 4, 1),
        ('ramified-log', 2, [1], [1+L], 6, 1),
        ('observable', 2, [1], [1+L], 5, sp.Rational(3,2)),
        ('two-log-generators', 1, [1,2], [L,1+L**2], 4, 1),
    ]
    for name,p,gaps,polys,n,q in cases:
        u = picard(p,gaps,polys,n)
        closed = theorem_jet(p,gaps,polys,n,q)
        check(f'{name}/independent-Picard/depth={n}', closed.equals(u.power(q)))
        check(f'{name}/forward-residual/depth={n}',
              (u.power(p)*(1+perturbation(u,gaps,polys))-1).equals(0))
        for k in indices(len(gaps),n):
            c = coeff(p,gaps,polys,k,q)
            bound = sum(ki*sp.degree(P,L) for ki,P in zip(k,polys))
            check(f'{name}/degree-bound/k={k}', c == 0 or sp.degree(c,L) <= bound)

    # Ramified inverse with an independently known exact radical formula.
    t=sp.Symbol('t',positive=True)
    exact_u = sp.sqrt(2/(1+sp.sqrt(1+4*t**2)))
    exact_series = sp.series(exact_u,t,0,18).removeO()
    model_series = sum(coeff(2,[2],[1],(n,))*t**(2*n) for n in range(9))
    check('ramified/exact-radical', sp.expand(exact_series-model_series)==0)

    # A collision case: multiple labelled multiindices yield the same weight.
    mixed = {}
    for k in indices(2,7):
        w=weight(k,[1,2])
        if w<=7:
            mixed[w]=sp.expand(mixed.get(w,0)+coeff(1,[1,2],[1,1],k))
    G=sum(c*y**(1+w) for w,c in mixed.items())
    check('resonance/x+x^2+x^3/residual',
          sp.series(G+G**2+G**3-y,y,0,9).removeO()==0)
    check('resonance/cancelled-weight-3', mixed[3]==0)

    for gaps,cut in [([1,2],sp.Rational(7,2)),
                     ([sp.sqrt(2)-1,sp.sqrt(3)-1],2),
                     ([sp.Rational(1,2),sp.sqrt(2)],3),
                     ([1,sp.sqrt(2)-1],4*sp.sqrt(2)-4)]:
        found,boundary=weighted_bfs(gaps,cut)
        minimum=min(gaps,key=lambda z: float(z))  # ONLY a finite test-bound choice;
        # Confirm the selected minimum exactly, never use it as an ordering oracle.
        assert all(sp.simplify(d-minimum).is_nonnegative for d in gaps)
        maxdegree=int(sp.ceiling(cut/minimum))
        brute={k for k in indices(len(gaps),maxdegree) if less(weight(k,gaps),cut)}
        check(f'enumeration/cut={cut}/gaps={gaps}',set(found)==brute)
        wb=[weight(k,gaps) for k in boundary]
        wstar=wb[0]
        for w in wb[1:]:
            if less(w,wstar): wstar=w
        omitted=[k for k in indices(len(gaps),maxdegree+1) if not less(weight(k,gaps),cut)]
        check(f'frontier/cut={cut}/gaps={gaps}',
              all(sp.simplify(weight(k,gaps)-wstar).is_nonnegative for k in omitted))

    expected=[-1,sp.sqrt(2),-3+sp.sqrt(2)/2,-4+17*sp.sqrt(2)/3]
    check('archived-question/sqrt2-coefficients', all(
        sp.simplify(coeff(1,[sp.sqrt(2)-1],[1],(n,))-c)==0
        for n,c in enumerate(expected,1)))
    return mixed


def bisect_monotone(f,target,lo,hi):
    """High-precision floating-point bisection, NOT interval certification."""
    if not f(lo)<=target<=f(hi):
        raise ValueError('invalid numerical bracket')
    for _ in range(600):
        mid=(lo+hi)/2
        if mid==lo or mid==hi: break
        if f(mid)<target: lo=mid
        else: hi=mid
    return (lo+hi)/2


def numerical_tests():
    mp.mp.dps=100
    alpha=mp.sqrt(2)
    f1=lambda x: x+x*x*(1+mp.log(x))
    f2=lambda x: x+mp.power(x,alpha)
    lower1=1-2*mp.exp(-mp.mpf(5)/2)
    out=[]
    for label,f,lower,gaps,polys in [('log',f1,lower1,[1],[1+L]),
                                    ('sqrt2',f2,mp.mpf(1),[sp.sqrt(2)-1],[1])]:
        cfunc=[sp.lambdify(L,coeff(1,gaps,polys,(n,)),'mpmath') for n in range(9)]
        gap=mp.mpf(1) if label=='log' else alpha-1
        for digits in [2,4,8]:
            yy=mp.power(10,-digits)
            root=bisect_monotone(f,yy,yy/2,2*yy)
            for n in [1,3,5,7]:
                approx=sum(cfunc[j](mp.log(yy))*mp.power(yy,1+j*gap) for j in range(n+1))
                error=abs(approx-root)
                residual=abs(f(approx)-yy)
                bound=residual/lower
                next_term=cfunc[n+1](mp.log(yy))*mp.power(yy,1+(n+1)*gap)
                ratio=(root-approx)/next_term
                check(f'numeric/{label}/y=1e-{digits}/depth={n}',
                      error<=bound*(1+mp.mpf('1e-20'))+mp.mpf('1e-95'))
                out.append({'model':label,'y':f'1e-{digits}','depth':n,
                            'absolute_error':mp.nstr(error,16),
                            'residual_over_slope':mp.nstr(bound,16),
                            'error_over_next_term':mp.nstr(ratio,16)})
    return out


def latex_number(s):
    value=mp.mpf(s)
    if value==0: return '0'
    e=int(mp.floor(mp.log10(abs(value))))
    mant=value/mp.power(10,e)
    return f'{float(mant):.5f}\\times 10^{{{e}}}'


def write_outputs(numerics,mixed):
    report={
        'scope':'Independent mathematical verification; the Wolfram Language package was NOT executed.',
        'native_wolfram_status':'Unavailable: connected evaluator returned HTTP 404; no local kernel found.',
        'versions':{'python':platform.python_version(),'sympy':sp.__version__,'mpmath':mp.__version__},
        'precision_decimal_digits':100,
        'tests_total':len(RESULTS),'tests_passed':sum(x['passed'] for x in RESULTS),
        'tests':RESULTS,'numerical_results':numerics,
        'log_blocks':{str(n):str(coeff(1,[1],[1+L],(n,))) for n in range(9)},
        'sqrt2_coefficients':{str(n):str(coeff(1,[sp.sqrt(2)-1],[1],(n,))) for n in range(9)},
        'resonant_coefficients':{str(w):str(c) for w,c in mixed.items()}}
    (HERE/'verification-results.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=[report['scope'],report['native_wolfram_status'],
           json.dumps(report['versions']),
           f"PASS: {report['tests_passed']} / {report['tests_total']} mathematical checks.",
           'Numerics use floating point, not interval arithmetic.','']
    lines += [f"{'PASS' if r['passed'] else 'FAIL'} {r['name']}" for r in RESULTS]
    (HERE/'verification-report.txt').write_text('\n'.join(lines)+'\n')
    rows=[]
    for r in numerics:
        if r['depth'] in [1,3,5]:
            rows.append(f"{r['model']} & $10^{{-{r['y'].split('-')[1]}}}$ & {r['depth']} & "
                        f"${latex_number(r['absolute_error'])}$ & "
                        f"${latex_number(r['residual_over_slope'])}$ \\\\")
    (ROOT/'Article'/'numerical-table.tex').write_text('\n'.join(rows)+'\n')
    (ROOT/'Article'/'verification-count.tex').write_text(str(len(RESULTS)))
    blocks=[]
    for n in range(5):
        blocks.append(f"Q_{{{n}}}(L) &= {sp.latex(coeff(1,[1],[1+L],(n,)))}")
    (ROOT/'Article'/'log-blocks.tex').write_text(' \\\\\n'.join(blocks)+'\n')
    print(lines[0]); print(lines[3])


def main():
    mixed=symbolic_tests()
    numerics=numerical_tests()
    write_outputs(numerics,mixed)

if __name__=='__main__':
    main()
