#!/usr/bin/env python3
"""Independent mathematical checks, not a substitute for running the WL tests.

Uses a coefficient-operator implementation AND independently builds/composes
ordinary epsilon-series, plus 120-digit numerical bisection. No network access.
Run: python validation/validate.py
"""
from __future__ import annotations
import itertools, json, math, pathlib, sys
import sympy as S
import mpmath as mp

ROOT = pathlib.Path(__file__).resolve().parents[1]
L = S.Symbol('L', real=True)
CHECKS: list[dict] = []

def check(name: str, condition: bool, detail: str = '') -> None:
    ok = bool(condition)
    CHECKS.append({'name': name, 'passed': ok, 'detail': detail})
    if not ok:
        raise AssertionError(name + ': ' + detail)

def coeff(alpha, ds, ps, k):
    alpha = S.sympify(alpha)
    n = sum(k)
    if n == 0:
        return S.Integer(1)
    A = S.simplify(sum(S.sympify(d)*ki for d,ki in zip(ds,k)))
    p = S.expand(S.prod(S.sympify(v)**ki for v,ki in zip(ps,k)))
    for j in range(1,n):
        p = S.expand(S.diff(p,L) + (1+A+alpha*j)*p)
    return S.expand((-1)**n*p/(alpha**n*S.prod(S.factorial(ki) for ki in k)))

def indices(ds, bound):
    ds = list(map(S.sympify, ds))
    bound = S.sympify(bound)
    out = []
    def visit(j, remainder, prefix):
        if j == len(ds):
            out.append(tuple(prefix)); return
        top = int(S.floor(S.simplify(remainder/ds[j])))
        for k in range(top+1):
            visit(j+1,S.simplify(remainder-k*ds[j]),prefix+[k])
    visit(0,bound,[])
    return out

# Independent ordinary epsilon-series arithmetic. Coefficients are exact
# polynomials in L and auxiliary markers, not generalized powers of y.
def add(a,b,N):
    return [S.expand((a[i] if i<len(a) else 0)+(b[i] if i<len(b) else 0)) for i in range(N+1)]
def scale(a,c,N):
    return [S.expand(c*(a[i] if i<len(a) else 0)) for i in range(N+1)]
def mul(a,b,N):
    return [S.expand(sum(a[j]*b[i-j] for j in range(i+1) if j<len(a) and i-j<len(b))) for i in range(N+1)]
def power_unit(u,p,N):
    assert S.simplify(u[0]-1)==0
    v=list(u[:N+1])+[S.Integer(0)]*max(0,N+1-len(u));v[0]=0
    term=[S.Integer(1)]+[S.Integer(0)]*N; ans=list(term)
    factor=S.Integer(1)
    for k in range(1,N+1):
        term=mul(term,v,N);factor=S.expand(factor*(p-k+1)/k)
        ans=add(ans,scale(term,factor,N),N)
    return ans

def log_unit(u,N):
    v=list(u[:N+1])+[S.Integer(0)]*max(0,N+1-len(u));v[0]=0
    term=[S.Integer(1)]+[S.Integer(0)]*N;ans=[S.Integer(0)]*(N+1)
    for k in range(1,N+1):
        term=mul(term,v,N)
        ans=add(ans,scale(term,S.Rational((-1)**(k+1),k),N),N)
    return ans

def poly_of_series(p,series,N):
    out=[S.Integer(0)]*(N+1)
    for c in S.Poly(p,L).all_coeffs():
        out=mul(out,series,N);out[0]=S.expand(out[0]+c)
    return out

def residual_series(u,alpha,ds,ps,markers,N):
    lu=log_unit(u,N);lu[0]+=L
    bracket=[S.Integer(1)]+[S.Integer(0)]*N
    for d,p,z in zip(ds,ps,markers):
        h=mul(power_unit(u,d,N),poly_of_series(p,lu,N),N)
        bracket=add(bracket,[S.Integer(0)]+scale(h,z,N)[:N],N)
    out=mul(power_unit(u,alpha,N),bracket,N);out[0]-=1
    return list(map(S.expand,out))

def weak_compositions(n,m):
    if m==0:
        if n==0:yield ()
        return
    if m==1:
        yield (n,);return
    for k in range(n+1):
        for tail in weak_compositions(n-k,m-1):yield (k,)+tail

def compare_with_independent_recursion(name,alpha,ds,ps,N):
    alpha=S.sympify(alpha);ds=list(map(S.sympify,ds));ps=list(map(S.sympify,ps))
    z=S.symbols('z0:'+str(len(ds)))
    # Solve one ordinary epsilon coefficient at a time: slope is alpha.
    u=[S.Integer(1)]+[S.Integer(0)]*N
    for n in range(1,N+1):
        residual=residual_series(u,alpha,ds,ps,z,n)[n]
        u[n]=S.expand(-residual/alpha)
        expected=S.expand(sum(coeff(alpha,ds,ps,k)*S.prod(zz**kk for zz,kk in zip(z,k))
                            for k in weak_compositions(n,len(ds))))
        check(f'{name}: epsilon coefficient {n}',S.simplify(u[n]-expected)==0)
    check(f'{name}: full composition residual', all(S.simplify(v)==0 for v in residual_series(u,alpha,ds,ps,z,N)))


def wl_structure(path):
    text=path.read_text();stack=[];i=0;comment=0;string=False;clean=[]
    while i<len(text):
        pair=text[i:i+2];ch=text[i]
        if comment:
            if pair=='(*':comment+=1;i+=2;continue
            if pair=='*)':comment-=1;i+=2;continue
            i+=1;continue
        if string:
            if ch=='\\':i+=2;continue
            if ch=='"':string=False
            i+=1;continue
        if pair=='(*':comment=1;i+=2;continue
        if ch=='"':string=True;i+=1;continue
        clean.append(ch)
        if ch in '[{(':stack.append(ch)
        elif ch in ']})':
            if not stack or '[{('[']})'.index(ch)]!=stack.pop():
                return False,''
        i+=1
    return not stack and not comment and not string,''.join(clean)


def symbolic_checks():
    compare_with_independent_recursion('log model',1,[1],[1+L],6)
    compare_with_independent_recursion('irrational power',1,[S.sqrt(2)-1],[1],7)
    compare_with_independent_recursion('ramified leading term',2,[1],[1],5)
    compare_with_independent_recursion('mixed logarithmic grid',S.Rational(3,2),
        [S.sqrt(2)-1,1],[1+L,2-L],3)
    compare_with_independent_recursion('resonant grid',1,[1,2],[1,2],4)
    check('known logarithmic y^4 coefficient',
          coeff(1,[1],[1+L],(3,)) == -5*L**3-S.Rational(41,2)*L**2-27*L-S.Rational(23,2))
    check('known logarithmic y^5 coefficient',
          coeff(1,[1],[1+L],(4,)) == 14*L**4+S.Rational(241,3)*L**3+S.Rational(335,2)*L**2+151*L+S.Rational(299,6))
    for n in range(11):
        check(f'Catalan specialization n={n}',coeff(1,[1],[1],(n,))==(-1)**n*S.catalan(n))
    check('rational noninteger coefficients',
          [coeff(1,[S.Rational(2,5)],[1],(n,)) for n in range(1,6)] ==
          [-1,S.Rational(7,5),-S.Rational(56,25),S.Rational(483,125),-7])
    p=S.symbols('p',positive=True)
    for n in range(1,8):
        generalized=(-1)**n/S.factorial(n)*S.prod(n*(p-1)+j for j in range(2,n+1))
        check(f'general monomial product n={n}',S.expand(coeff(1,[p-1],[1],(n,))-generalized)==0)
    d=S.sqrt(2)-1;cut=3*d
    check('exact irrational boundary enumeration',indices([d],cut)==[(0,),(1,),(2,),(3,)])
    frontier=indices([1,2],2)
    omitted=S.expand(sum(coeff(1,[1,2],[1,2],k) for k in frontier if k[0]+2*k[1]==2))
    check('resonant first-omitted cancellation',omitted==0)
    check('positive minimum slope for log model',1-2*mp.e**(-mp.mpf(5)/2)>0)
    for path in sorted(ROOT.rglob('*.wl'))+sorted(ROOT.rglob('*.wlt'))+sorted(ROOT.rglob('*.m')):
        ok,clean=wl_structure(path)
        check('WL structural delimiters: '+str(path.relative_to(ROOT)),ok,
              'Delimiter/string/comment check only; not native syntax or execution testing.')
        if path.name=='RealInverseAsymptotics.wl' and path.parent.name=='Kernel':
            check('no unsafe PowerExpand calls','PowerExpand[' not in clean)
            check('no InverseFunction calls','InverseFunction[' not in clean)


def bisect_positive(f,y):
    lo=y/2;hi=2*y
    while f(lo)>y:lo/=2
    while f(hi)<y:hi*=2
    for _ in range(500):
        mid=(lo+hi)/2
        if f(mid)<y:lo=mid
        else:hi=mid
        if hi-lo<mp.mpf('1e-110')*y:break
    return (lo+hi)/2


def numerical_checks():
    mp.mp.dps=120
    rows=[]
    for name in ['log','irrational']:
        p=mp.sqrt(2)
        f=(lambda x:x+x*x*(1+mp.log(x))) if name=='log' else (lambda x:x+x**p)
        ds=[S.Integer(1)] if name=='log' else [S.sqrt(2)-1]
        ps=[1+L] if name=='log' else [1]
        m=1-2*mp.exp(-mp.mpf(5)/2) if name=='log' else mp.mpf(1)
        for ye in [2,4,8]:
            y=mp.mpf(10)**(-ye);root=bisect_positive(f,y)
            for N in [1,2,3,4,5]:
                approx=y
                for n in range(1,N+1):
                    c=S.lambdify(L,coeff(1,ds,ps,(n,)),'mpmath')(mp.log(y))
                    approx+=c*y**(1+n*(1 if name=='log' else p-1))
                error=abs(approx-root);res=abs(f(approx)-y);bound=res/m
                q=S.lambdify(L,coeff(1,ds,ps,(N+1,)),'mpmath')(mp.log(y))
                next_term=q*y**(1+(N+1)*(1 if name=='log' else p-1))
                check(f'numeric residual bound {name}, y=1e-{ye}, N={N}',
                      error <= bound*(1+mp.mpf('1e-70'))+mp.mpf('1e-108')*y)
                rows.append({'model':name,'y':f'1e-{ye}','correction_blocks':N,
                    'absolute_error':mp.nstr(error,16),'residual_bound':mp.nstr(bound,16),
                    'error_over_next_term':mp.nstr((root-approx)/next_term,16)})
    return rows


def main():
    symbolic_checks()
    rows=numerical_checks()
    output={'python_version':sys.version.split()[0], 'sympy_version':S.__version__,
            'mpmath_version':mp.__version__,'arithmetic_decimal_digits':120,
            'native_wolfram_tests_executed':False,
            'native_wolfram_status':'Unavailable: no local Wolfram kernel, and the Wolfram connector endpoint returned HTTP 404.',
            'status':'PASS','check_count':len(CHECKS),'checks':CHECKS,'numerical_examples':rows}
    destination=ROOT/'validation'/'results.json'
    destination.write_text(json.dumps(output,indent=2)+'\n')
    print(f'PASS: {len(CHECKS)} independent mathematical and structural checks.')
    print('Native Wolfram execution: NOT performed; see Tests/RunTests.wl.')
    print(destination)

if __name__=='__main__':main()
