"""Exact half-spectrum prototype for real Fourier-polynomial coefficients.

A frequency is in Q(sqrt(2)); polynomial coefficients are in Q(sqrt(2))[i].
This is an independent algebra prototype, NOT a replacement for the package's
arbitrary exact-real frequency support, assumptions, budgets, or public APIs.
Only nonnegative frequencies are stored. Negative modes are conjugates.
No approximate comparison, floating-point coefficient, or frequency truncation
is used. Python 3.10+; standard library only.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction as F
from math import factorial
from typing import Iterable, Mapping

@dataclass(frozen=True)
class Q2:
    a: F = F(0)
    b: F = F(0)
    def __post_init__(self):
        object.__setattr__(self, 'a', F(self.a))
        object.__setattr__(self, 'b', F(self.b))
    @staticmethod
    def of(v):
        if isinstance(v, Q2): return v
        if isinstance(v, (int, F)): return Q2(F(v))
        return NotImplemented
    def __add__(self, other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else Q2(self.a+o.a,self.b+o.b)
    __radd__=__add__
    def __neg__(self): return Q2(-self.a,-self.b)
    def __sub__(self,other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else self+-o
    def __rsub__(self,other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else o+-self
    def __mul__(self,other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else Q2(self.a*o.a+2*self.b*o.b,self.a*o.b+self.b*o.a)
    __rmul__=__mul__
    def __truediv__(self,other):
        o=Q2.of(other)
        if o is NotImplemented: return NotImplemented
        norm=o.a*o.a-2*o.b*o.b
        if norm==0: raise ZeroDivisionError('zero quadratic-field divisor')
        return self*Q2(o.a/norm,-o.b/norm)
    def __rtruediv__(self,other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else o/self
    def __pow__(self,n):
        if not isinstance(n,int): return NotImplemented
        if n<0: return (Q2(1)/self)**(-n)
        out=Q2(1); base=self
        while n:
            if n&1: out=out*base
            n//=2
            if n: base=base*base
        return out
    def sign(self):
        sa=(self.a>0)-(self.a<0); sb=(self.b>0)-(self.b<0)
        if not sa: return sb
        if not sb or sa==sb: return sa
        # Squaring is valid here because the two positive magnitudes compete.
        return sa if self.a*self.a>2*self.b*self.b else sb
    def __lt__(self,other):
        o=Q2.of(other)
        return NotImplemented if o is NotImplemented else (self-o).sign()<0
    def __bool__(self): return self.a!=0 or self.b!=0
    def __str__(self): return str(self.a) if not self.b else f'({self.a})+({self.b})*sqrt(2)'

@dataclass(frozen=True)
class C2:
    re: Q2 = Q2()
    im: Q2 = Q2()
    def __post_init__(self):
        r=Q2.of(self.re); i=Q2.of(self.im)
        if r is NotImplemented or i is NotImplemented: raise TypeError('exact Q(sqrt(2)) coefficients required')
        object.__setattr__(self,'re',r); object.__setattr__(self,'im',i)
    @staticmethod
    def of(v):
        if isinstance(v,C2): return v
        q=Q2.of(v)
        return NotImplemented if q is NotImplemented else C2(q)
    def __add__(self,other):
        o=C2.of(other)
        return NotImplemented if o is NotImplemented else C2(self.re+o.re,self.im+o.im)
    __radd__=__add__
    def __neg__(self): return C2(-self.re,-self.im)
    def __sub__(self,other):
        o=C2.of(other)
        return NotImplemented if o is NotImplemented else self+-o
    def __mul__(self,other):
        o=C2.of(other)
        return NotImplemented if o is NotImplemented else C2(self.re*o.re-self.im*o.im,self.re*o.im+self.im*o.re)
    __rmul__=__mul__
    def conj(self): return C2(self.re,-self.im)
    def __bool__(self): return bool(self.re) or bool(self.im)

Poly=tuple[C2,...]
ZERO=Q2()

def poly(values: Iterable=()) -> Poly:
    p=[C2.of(v) for v in values]
    if any(v is NotImplemented for v in p): raise TypeError('nonexact polynomial coefficient')
    while p and not p[-1]: p.pop()
    return tuple(p)

def padd(a: Poly,b: Poly) -> Poly:
    return poly((a[k] if k<len(a) else C2())+(b[k] if k<len(b) else C2()) for k in range(max(len(a),len(b))))

def pconj(a: Poly) -> Poly: return poly(c.conj() for c in a)
def pscale(a: Poly,c) -> Poly: return poly(v*c for v in a)
def pdiff(a: Poly) -> Poly: return poly(k*a[k] for k in range(1,len(a)))

@dataclass
class Work:
    polynomial_products: int = 0
    coefficient_products: int = 0

def pmul(a: Poly,b: Poly,work: Work|None=None) -> Poly:
    if work is not None:
        work.polynomial_products+=1
        work.coefficient_products+=len(a)*len(b)
    if not a or not b: return ()
    out=[C2()]*(len(a)+len(b)-1)
    for j,c in enumerate(a):
        for k,d in enumerate(b): out[j+k]=out[j+k]+c*d
    return poly(out)

def add_mode(out: dict[Q2,Poly], w: Q2,p: Poly):
    q=padd(out.get(w,()),p)
    if q: out[w]=q
    else: out.pop(w,None)

def full_mul(a: Mapping[Q2,Poly],b: Mapping[Q2,Poly],work: Work|None=None) -> dict[Q2,Poly]:
    """Independent reference: ordinary full Cartesian convolution."""
    out={}
    for w,p in a.items():
        for v,q in b.items(): add_mode(out,w+v,pmul(p,q,work))
    return out

def full_euler(a: Mapping[Q2,Poly]) -> dict[Q2,Poly]:
    out={}
    for w,p in a.items(): add_mode(out,w,padd(pdiff(p),pscale(p,C2(0,w))))
    return out

@dataclass
class Hermitian:
    modes: dict[Q2,Poly]
    def __post_init__(self):
        cleaned={}
        for w,p in self.modes.items():
            w=Q2.of(w)
            if w is NotImplemented or w.sign()<0: raise ValueError('half-spectrum frequencies must be nonnegative')
            p=poly(p)
            if not w and any(c.im for c in p): raise ValueError('zero-mode polynomial must be real')
            if p: add_mode(cleaned,w,p)
        self.modes=cleaned
    @classmethod
    def from_full(cls,full: Mapping[Q2,Poly]):
        f={Q2.of(w):poly(p) for w,p in full.items() if poly(p)}
        if any(f.get(-w,())!=pconj(p) for w,p in f.items()):
            raise ValueError('full spectrum is not Hermitian')
        return cls({w:p for w,p in f.items() if w.sign()>=0})
    def full(self) -> dict[Q2,Poly]:
        out=dict(self.modes)
        out.update({-w:pconj(p) for w,p in self.modes.items() if w})
        return out
    def full_frequency_count(self):
        return 2*sum(bool(w) for w in self.modes)+int(ZERO in self.modes)
    def mul(self,other: Hermitian,work: Work|None=None) -> Hermitian:
        out={}; a0=self.modes.get(ZERO,()); b0=other.modes.get(ZERO,())
        aa=[(w,p) for w,p in self.modes.items() if w]
        bb=[(w,p) for w,p in other.modes.items() if w]
        if a0 and b0: add_mode(out,ZERO,pmul(a0,b0,work))
        if a0:
            for w,p in bb: add_mode(out,w,pmul(a0,p,work))
        if b0:
            for w,p in aa: add_mode(out,w,pmul(p,b0,work))
        for w,p in aa:
            for v,q in bb:
                add_mode(out,w+v,pmul(p,q,work))
                cross=pmul(p,pconj(q),work); difference=w-v
                if difference.sign()>0: add_mode(out,difference,cross)
                elif difference.sign()<0: add_mode(out,-difference,pconj(cross))
                else: add_mode(out,ZERO,padd(cross,pconj(cross)))
        return Hermitian(out)
    def euler(self): return Hermitian(full_euler(self.modes))
    def add(self,other: Hermitian):
        out=dict(self.modes)
        for w,p in other.modes.items(): add_mode(out,w,p)
        return Hermitian(out)
    def scale_real(self,c):
        c=Q2.of(c)
        if c is NotImplemented: raise TypeError('real quadratic-field scale required')
        return Hermitian({w:pscale(p,c) for w,p in self.modes.items()})
    def power(self,n: int):
        if not isinstance(n,int) or n<0: raise ValueError('nonnegative integer power required')
        out=Hermitian({ZERO:poly([1])}); base=self
        while n:
            if n&1: out=out.mul(base)
            n//=2
            if n: base=base.mul(base)
        return out
    def lagrange_single(self,n: int,p=1,r=1,gap=1):
        """One-perturbation Euler coefficient, excluding the source-weight monomial."""
        if not isinstance(n,int) or n<0: raise ValueError('nonnegative depth required')
        if n==0: return Hermitian({ZERO:poly([1])})
        p=Q2.of(p); r=Q2.of(r); gap=Q2.of(gap)
        if not p: raise ZeroDivisionError('leading source power cannot be zero')
        out=self.power(n)
        for j in range(1,n): out=out.euler().add(out.scale_real(r+n*gap+p*j))
        return out.scale_real(((-1)**n)*r/(p**n*factorial(n)))
