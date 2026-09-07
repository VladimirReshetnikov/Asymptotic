#!/usr/bin/env python3
"""Independent mathematical checks; does NOT execute Wolfram Language.
Requires Python >=3.10, SymPy and mpmath. No network access is used.
The coefficient implementation and the independent unit-series recurrences
below are intentionally distinct. Run from any directory.
"""
from __future__ import annotations
import json
import math
from functools import cmp_to_key
from pathlib import Path
import sympy as s
import mpmath as mp

L = s.Symbol('L', real=True)
Y = s.Symbol('y', positive=True)
ROOT = Path(__file__).resolve().parent
checks: list[dict] = []

def canonical(x):
    return s.simplify(s.expand(x))

def cmp(a, b):
    d = canonical(a-b)
    if d == 0: return 0
    if d.is_positive is True: return 1
    if d.is_negative is True: return -1
    raise ValueError(f'Undecidable exact comparison: {a}, {b}')

def merge(blocks):
    out = {}
    for a,p in blocks:
        a = canonical(a)
        out[a] = s.expand(out.get(a,0)+p)
    return [(a,s.expand(p)) for a,p in sorted(out.items(), key=cmp_to_key(lambda u,v:cmp(u[0],v[0]))) if s.expand(p)!=0]

def lattice(weights, bound):
    if not weights:
        yield (); return
    top = s.floor(canonical(bound/weights[0]))
    if not top.is_Integer: raise ValueError('Noninteger enumeration bound')
    for k in range(int(top)+1):
        for rest in lattice(weights[1:],canonical(bound-k*weights[0])):
            yield (k,)+rest

def inverse(original, cutoff):
    original = merge([(s.sympify(a),s.sympify(p)) for a,p in original])
    p,a = original[0]; q=1/p
    if a.has(L) or not a.is_positive: raise ValueError('Bad leading term')
    corrections = [(canonical(alpha/p-1),s.expand(poly.subs(L,L/p)/a)) for alpha,poly in original[1:]]
    if not corrections:
        return {'blocks':[(q,s.S.One)],'remainder':(s.oo,0),'p':p,'a':a,'q':q,'original':original,'cutoff':cutoff}
    weights,polys=zip(*corrections)
    dmin=min(weights,key=cmp_to_key(cmp)); b=canonical(cutoff-q)
    bound=canonical(s.ceiling(canonical(b/dmin))*dmin)
    rows=[]
    for k in lattice(weights,bound):
        n=sum(k)
        if n:
            beta=canonical(sum(ki*di for ki,di in zip(k,weights)))
            rows.append((k,beta))
    excluded=[(k,beta) for k,beta in rows if cmp(beta,b)>=0]
    star=min((beta for k,beta in excluded),key=cmp_to_key(cmp))
    dstar=max(sum(ki*s.degree(poly,L) for ki,poly in zip(k,polys)) for k,beta in excluded if cmp(beta,star)==0)
    blocks=[(q,s.S.One)]
    for k,beta in rows:
        if cmp(beta,b)>=0: continue
        n=sum(k); poly=s.prod(P**ki for P,ki in zip(polys,k))
        for j in range(1,n):
            poly=s.expand(s.diff(poly,L)+(beta+q+j)*poly)
        poly=s.expand(q*(-1)**n*poly/s.prod(s.factorial(ki) for ki in k))
        blocks.append((canonical(q+beta),poly))
    return {'blocks':merge(blocks),'remainder':(canonical(q+star),int(dstar)),
            'p':p,'a':a,'q':q,'original':original,'cutoff':cutoff}

def convolution(a,b,N):
    return [s.expand(sum(a[k]*b[n-k] for k in range(n+1) if k<len(a) and n-k<len(b))) for n in range(N+1)]

def unit_power(a, q, N):
    """From A B'=q B A', with A(0)=B(0)=1. No inversion formula."""
    a=list(a)+[s.S.Zero]*max(0,N+1-len(a)); b=[s.S.One]
    for n in range(1,N+1):
        b.append(s.expand(sum(((q+1)*k-n)*a[k]*b[n-k] for k in range(1,n+1))*s.Rational(1,n)))
    return b

def unit_log(a,N):
    """From A (log A)'=A'."""
    a=list(a)+[s.S.Zero]*max(0,N+1-len(a)); out=[s.S.Zero]
    for n in range(1,N+1):
        out.append(s.expand(a[n]-s.Rational(1,n)*sum(k*out[k]*a[n-k] for k in range(1,n))))
    return out

def implicit_log_coefficients(N):
    """Solve U=-s(1+U)^2(1+L+log(1+U)) recursively."""
    a=[s.S.One]
    for n in range(1,N+1):
        power=unit_power(a,s.Integer(2),n-1)
        logs=unit_log(a,n-1); logs[0]=1+L
        a.append(s.expand(-convolution(power,logs,n-1)[n-1]))
    return a

def implicit_power_coefficients(alpha,N):
    a=[s.S.One]
    for n in range(1,N+1):
        a.append(s.expand(-unit_power(a,alpha,n-1)[n-1]))
    return a

def muljet(A,B,cut):
    return merge([(canonical(a+b),s.expand(p*q)) for a,p in A for b,q in B if cmp(a+b,cut)<0])

def compose_residual(data,cut=None):
    q=data['q']; a=data['a']
    cut=canonical(data['cutoff']+1-q if cut is None else cut)
    unit=[(canonical(alpha-q),p) for alpha,p in data['blocks'][1:]]
    vmin=unit[0][0] if unit else s.oo
    out=[(s.S.One,-s.S.One)]
    z=s.Symbol('z')
    for alpha,poly in data['original']:
        base=canonical(q*alpha)
        if cmp(base,cut)>=0: continue
        N=int(s.floor(canonical((cut-base)/vmin))) if unit else 0
        # Auxiliary Taylor coefficients obtained from differential recurrences.
        Az=[s.S.One,s.S.One]+[s.S.Zero]*max(0,N-1)
        power=unit_power(Az,alpha,N)
        lg=unit_log(Az,N); lg[0]=q*L
        logpoly=[s.S.Zero]*(N+1)
        lgpow=[s.S.One]+[s.S.Zero]*N
        for r in range(int(s.degree(poly,L))+1):
            c=s.expand(poly).coeff(L,r)/a
            logpoly=[s.expand(u+c*v) for u,v in zip(logpoly,lgpow)]
            lgpow=convolution(lgpow,lg,N)
        H=convolution(power,logpoly,N)
        upow=[(s.S.Zero,s.S.One)]
        for j in range(N+1):
            out += [(canonical(base+e),s.expand(H[j]*P)) for e,P in upow if cmp(base+e,cut)<0]
            upow=muljet(upow,unit,canonical(cut-base))
    return merge([(e,P) for e,P in out if cmp(e,cut)<0])

def check(name, condition):
    ok=bool(condition)
    checks.append({'name':name,'passed':ok})
    if not ok: raise AssertionError(name)

def equal(a,b): return s.expand(a-b)==0

def bracket_check(path):
    """Static delimiter check only, not a Wolfram parser or evaluator."""
    text=path.read_text(); stack=[]; i=0; comments=0; string=False
    while i<len(text):
        if comments:
            if text.startswith('(*',i): comments+=1; i+=2
            elif text.startswith('*)',i): comments-=1; i+=2
            else:i+=1
            continue
        if string:
            if text[i]=='\\':i+=2;continue
            if text[i]=='"':string=False
            i+=1;continue
        if text.startswith('(*',i):comments=1;i+=2;continue
        c=text[i]
        if c=='"':string=True
        elif c in '[{(':stack.append(c)
        elif c in ']})':
            if not stack or stack.pop() != {']':'[','}':'{',')':'('}[c]:return False
        i+=1
    return not stack and not comments and not string

def main():
    logdata=inverse([(1,1),(2,1+L)],s.Integer(10))
    logrec=implicit_log_coefficients(8)
    for n in range(1,9):
        P=dict(logdata['blocks'])[s.Integer(n+1)]
        check(f'log coefficient {n}: independent implicit recursion',equal(P,logrec[n]))
        direct=s.diff(Y**(2*n)*(1+s.log(Y))**n,Y,n-1)*(-1)**n/s.factorial(n)
        direct=s.expand(direct/Y**(n+1)).subs(s.log(Y),L)
        check(f'log coefficient {n}: direct derivatives',equal(P,direct))
        check(f'log coefficient {n}: Catalan leading term',equal(s.expand(P).coeff(L,n),(-1)**n*s.catalan(n)))
    alpha=s.sqrt(2); N=8
    irr=inverse([(1,1),(alpha,1)],canonical(1+(N+1)*(alpha-1)))
    irrec=implicit_power_coefficients(alpha,N)
    for n in range(1,N+1):
        coef=dict(irr['blocks'])[canonical(1+n*(alpha-1))]
        check(f'irrational coefficient {n}: independent recursion',equal(coef,irrec[n]))
    models=[
        ('logarithmic',[(1,1),(2,1+L)],s.Integer(7)),
        ('irrational',[(1,1),(s.sqrt(2),1)],s.Integer(3)),
        ('mixed',[(1,1),(s.sqrt(2),2),(s.Rational(3,2),1+L)],s.Integer(3)),
        ('resonant',[(1,1),(s.Rational(3,2),2),(2,-3)],s.Integer(4)),
        ('power core',[(2,1),(3,1)],s.Integer(3)),
        ('scaled logarithmic',[(s.Rational(3,2),3),(s.Rational(5,2),1+2*L)],s.Integer(3)),
        ('pure leading power',[(s.Rational(2,3),5)],s.Integer(4)),
        ('log squared',[(1,1),(2,L**2+2)],s.Integer(5)),
    ]
    for name,orig,cut in models:
        d=inverse(orig,cut)
        check(f'{name}: independent composition residual',compose_residual(d)==[])
    check('logarithmic remainder preserves log degree',inverse([(1,1),(2,1+L)],s.Integer(3))['remainder']==(3,2))
    check('irrational cutoff excludes boundary',len(inverse([(1,1),(alpha,1)],4*alpha-3)['blocks'])==4)
    res=inverse([(1,1),(s.Rational(3,2),2),(2,-3)],s.Integer(3))
    check('resonant y^2 coefficients aggregate',dict(res['blocks'])[s.Integer(2)]==9)
    bad=dict(res);bad['blocks']=list(res['blocks']);bad['blocks'][1]=(bad['blocks'][1][0],s.S.Zero)
    check('residual detects deliberately corrupted coefficient',compose_residual(bad)!=[])
    for path in sorted((ROOT.parent/'Kernel').glob('*')):
        if path.suffix in {'.wl','.m'}:check('static delimiters: '+path.name,bracket_check(path))
    for path in sorted((ROOT.parent/'Tests').glob('*')):
        if path.suffix in {'.wlt','.wls'}:check('static delimiters: '+path.name,bracket_check(path))
    mp.mp.dps=180
    numerical=[]
    for example in ['logarithmic','irrational']:
        for ytext in ['1e-2','1e-4','1e-8']:
            y=mp.mpf(ytext)
            if example=='logarithmic':
                fn=lambda x:x+x*x*(1+mp.log(x))
                df=lambda x:1+x*(3+2*mp.log(x))
            else:
                al=mp.sqrt(2);fn=lambda x:x+x**al;df=lambda x:1+al*x**(al-1)
            root=mp.findroot(lambda x:fn(x)-y,y,df=df,solver='newton',tol=mp.mpf('1e-160'))
            for N in [2,4,6]:
                if example=='logarithmic':
                    d=inverse([(1,1),(2,1+L)],s.Integer(N+2))
                else:
                    d=inverse([(1,1),(s.sqrt(2),1)],canonical(1+(N+1)*(s.sqrt(2)-1)))
                value=mp.mpf('0')
                for e,P in d['blocks']:
                    ef=mp.mpf(str(s.N(e,185)))
                    pf=s.lambdify(L,P,'mpmath')
                    value += y**ef*pf(mp.log(y))
                err=abs(value-root); rel=err/abs(root); resid=abs(fn(value)-y)
                numerical.append({'example':example,'y':ytext,'correction_order':N,
                    'relative_error':mp.nstr(rel,12),'absolute_error':mp.nstr(err,12),
                    'absolute_residual':mp.nstr(resid,12)})
                check(f'numerical {example}, y={ytext}, N={N}',value>0 and rel<mp.mpf('.02'))
    coeffs={str(n):str(dict(logdata['blocks'])[s.Integer(n+1)]) for n in range(1,9)}
    report={'python':__import__('sys').version.split()[0],'sympy':s.__version__,'mpmath':mp.__version__,
        'precision_decimal_digits':mp.mp.dps,'wolfram_language_execution':False,
        'wolfram_status':'Not executed: the available Wolfram service returned HTTP 404; no local Wolfram kernel was installed.',
        'passed':sum(c['passed'] for c in checks),'total':len(checks),'checks':checks,
        'logarithmic_coefficients':coeffs,'numerical_checks':numerical}
    (ROOT/'results.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=[f"{report['passed']}/{report['total']} independent mathematical/static checks passed.",
       f"Python {report['python']}; SymPy {s.__version__}; mpmath {mp.__version__}; {mp.mp.dps} decimal digits.",
       'Wolfram Language test suite: supplied, NOT EXECUTED.',report['wolfram_status'],'']
    lines += [('PASS ' if c['passed'] else 'FAIL ')+c['name'] for c in checks]
    lines += ['', 'Numerical relative errors (N counts corrections, not leading term):']
    lines += [f"{r['example']:12s} y={r['y']:5s} N={r['correction_order']} relative error={r['relative_error']}" for r in numerical]
    (ROOT/'results.txt').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines))

if __name__=='__main__':main()
