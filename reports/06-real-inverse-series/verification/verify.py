#!/usr/bin/env python3
"""Run reproducible symbolic and high-precision numerical checks.

Dependencies: SymPy and mpmath. This does NOT execute the Wolfram package.
All PASS claims refer to the independent Python reference and stated identities.
"""
from __future__ import annotations
import json, platform, sys, time
from pathlib import Path
from math import factorial
import sympy as S
import mpmath as mp
from reference import Model, L, compare, exact, add, scale

ROOT=Path(__file__).resolve().parent
checks=[]
def check(name,condition,detail=''):
    condition=bool(condition)
    checks.append({'name':name,'passed':condition,'detail':detail})
    print(('PASS ' if condition else 'FAIL ')+name,flush=True)
    if not condition:
        raise AssertionError(name+': '+detail)


def numeric_inverse(model,y,unit):
    p=mp.mpf(str(S.N(model.p,mp.mp.dps+10)))
    c=mp.mpf(str(S.N(model.c,mp.mp.dps+10)))
    s=mp.power(y/c,1/p); ell=mp.log(s)
    ds=[mp.mpf(str(S.N(d,mp.mp.dps+10))) for d in model.deltas]
    fs=[S.lambdify(L,P,'mpmath') for P in model.polynomials]
    dfs=[S.lambdify(L,S.diff(P,L),'mpmath') for P in model.polynomials]
    def equation(v):
        logv=ell+mp.log(v)
        return mp.power(v,p)*(1+sum(mp.power(s,d)*mp.power(v,d)*f(logv) for d,f in zip(ds,fs)))-1
    def slope(v):
        logv=ell+mp.log(v)
        return p*mp.power(v,p-1)+sum(mp.power(s,d)*mp.power(v,p+d-1)*((p+d)*f(logv)+df(logv)) for d,f,df in zip(ds,fs,dfs))
    v=mp.mpf(1)
    for _ in range(80):
        step=equation(v)/slope(v)
        v-=step
        if abs(step)<mp.eps*16:
            break
    else:
        raise RuntimeError('Numerical Newton did not converge.')
    approx=sum(mp.power(s,1+mp.mpf(str(S.N(w,mp.mp.dps+10))))*S.lambdify(L,P,'mpmath')(ell) for w,P in unit.items())
    return s*v,approx,abs(equation(v))


def main():
    start=time.time()
    x=S.Symbol('x',positive=True)
    logmodel=Model(1,1,(1,),(1+L,))
    known=[-L-1,2*L**2+5*L+3,-5*L**3-S.Rational(41,2)*L**2-27*L-S.Rational(23,2),
           14*L**4+S.Rational(241,3)*L**3+S.Rational(335,2)*L**2+151*L+S.Rational(299,6)]
    for n in range(1,9):
        p=logmodel.coefficient((n,),S.Integer(n))
        direct=S.expand((-1)**n*S.diff((x**2*(1+S.log(x)))**n,x,n-1)/S.factorial(n)/x**(n+1))
        check(f'log coefficient derivative identity n={n}',S.expand(direct.subs(S.log(x),L)-p)==0)
        check(f'Catalan highest log coefficient n={n}',S.expand(p).coeff(L,n)==(-1)**n*S.catalan(n))
        if n<=4:
            check(f'explicit log coefficient n={n}',S.expand(p-known[n-1])==0)
    alpha=S.sqrt(2)
    irr=Model(1,1,(alpha-1,),(S.Integer(1),))
    for n in range(1,9):
        expected=(-1)**n*S.prod(n*alpha-j for j in range(n-1))/S.factorial(n)
        check(f'irrational coefficient n={n}',S.simplify(irr.coefficient((n,),n*(alpha-1))-expected)==0)
    check('irrational third correction',S.simplify(irr.coefficient((3,),3*(alpha-1))+(6-alpha)/2)==0)
    models=[
      ('log',logmodel,S.Integer(6)),
      ('irrational',irr,4*(alpha-1)),
      ('mixed',Model(1,1,(alpha-1,S.Integer(1)),(S.Integer(1),L+1)),S.Integer(2)),
      ('resonant',Model(1,1,(S.Rational(1,2),S.Integer(1)),(L+1,2-L)),S.Rational(5,2)),
      ('nonunit-core',Model(2,3,(S.Rational(1,2),S.Integer(1)),(L+1,S.Integer(2))),S.Rational(5,2)),
      ('fractional-core',Model(S.Rational(3,2),2,(S.Rational(1,2),S.Rational(3,2)),(1-L,L**2+1)),S.Integer(3)),
      ('negative-correction',Model(1,1,(S.Rational(1,3),),(L-2,)),S.Rational(5,3)),
      ('pure-monomial',Model(S.Rational(3,2),2,(),()),S.Integer(3))
    ]
    traces={}; symbolic={}
    for name,m,A in models:
        l=m.lagrange(A); n,tr=m.newton(A)
        diff=add(l,scale(n,-1),A)
        check(name+': Lagrange equals independent Newton',not diff)
        check(name+': forward residual cancels below cutoff',not m.residual(l,A))
        traces[name]=tr
        symbolic[name]=[{'weight':str(w),'polynomial':str(p)} for w,p in l.items()]
    check('log strict cutoff tail',logmodel.remainder(S.Integer(2))==(S.Integer(3),2))
    check('irrational exact boundary tail',irr.remainder(4*(alpha-1))==(4*alpha-3,0))
    check('mixed tail',models[2][1].remainder(S.Integer(2))==(S.Integer(3),2))
    mixed=models[2][1].lagrange(S.Integer(2))
    check('mixed fourth perturbation retained',exact(4*(alpha-1)) in mixed)
    # Two integer-index descriptions contribute at weight 1 in the resonant case.
    res=models[3][1]
    expected=res.coefficient((2,0),S.Integer(1))+res.coefficient((0,1),S.Integer(1))
    check('resonant coefficients merged',S.expand(res.lagrange(S.Integer(2))[S.Integer(1)]-expected)==0)
    # A second direct derivative audit for a nonunit monomial core.
    m=models[4][1]; s=S.Symbol('s',positive=True)
    for ns in [(1,0),(2,0),(1,1),(3,0),(0,2)]:
        N=sum(ns); d=sum(k*dd for k,dd in zip(ns,m.deltas))
        Q=S.prod(P.subs(L,S.log(s))**k for P,k in zip(m.polynomials,ns))
        T=m.c**(N-1)/m.p*s**(m.p*(N-1)+d+1)*Q
        for _ in range(N-1):
            T=S.diff(T,s)/(m.c*m.p*s**(m.p-1))
        T=S.expand((-1)**N*T/S.prod(S.factorial(k) for k in ns)/s**(1+d)).subs(S.log(s),L)
        check('nonunit direct derivative '+str(ns),S.simplify(T-m.coefficient(ns,d))==0)
    numeric=[]
    mp.mp.dps=250
    for ystr in ['0.01','0.0001','1e-8','1e-20']:
        for N in [1,3,5]:
            u=logmodel.lagrange(S.Integer(N+1))
            y=mp.mpf(ystr); root,approx,nres=numeric_inverse(logmodel,y,u)
            err=abs(root-approx)
            denom=mp.power(y,N+2)*mp.power(abs(mp.log(y)),N+1)
            row={'model':'log','y':ystr,'corrections':N,'absolute_error':mp.nstr(err,18),
                 'scaled_error':mp.nstr(err/denom,18),'root_normalized_residual':mp.nstr(nres,5)}
            numeric.append(row)
            check(f'numeric log y={ystr} N={N}',err>0 and nres<mp.mpf('1e-240'))
    for name,m,A in models[1:7]:
        u=m.lagrange(A)
        for ystr in ['1e-6','1e-12']:
            root,approx,nres=numeric_inverse(m,mp.mpf(ystr),u)
            err=abs(root-approx)
            numeric.append({'model':name,'y':ystr,'absolute_error':mp.nstr(err,18),'root_normalized_residual':mp.nstr(nres,5)})
            check(f'numeric {name} y={ystr}',nres<mp.mpf('1e-240') and err<abs(root)*mp.mpf('1e-3'))
    report={'status':'PASS','test_count':len(checks),'checks':checks,'symbolic_blocks':symbolic,
            'newton_traces':traces,'numerical_checks':numeric,'environment':{'python':platform.python_version(),
            'sympy':S.__version__,'mpmath':mp.__version__,'precision_digits':mp.mp.dps},
            'wolfram_kernel_executed':False,'elapsed_seconds':round(time.time()-start,3)}
    (ROOT/'verification-report.json').write_text(json.dumps(report,indent=2)+'\n')
    # A small TeX table is generated from measured values, not hand-entered data.
    lines=['\\begin{tabular}{@{}rrrl@{}}','\\toprule',r'$y$ & corrections $N$ & $|g-g_N|$ & scaled error\\','\\midrule']
    for row in numeric:
        if row['model']=='log' and row['corrections'] in [1,3] and row['y']!='1e-20':
            y=mp.mpf(row['y']); err=mp.mpf(row['absolute_error'])
            e=int(mp.floor(mp.log10(err))); mant=err/mp.power(10,e)
            expy=int(mp.log10(y))
            lines.append(f'$10^{{{expy}}}$ & {row["corrections"]} & ${float(mant):.6f}\\times10^{{{e}}}$ & {float(mp.mpf(row["scaled_error"])):.6f}\\\\')
    lines+=['\\bottomrule','\\end{tabular}']
    (ROOT.parent/'article'/'numerical-table.tex').write_text('\n'.join(lines)+'\n')
    print(f'\n{len(checks)} checks passed in {report["elapsed_seconds"]} s.',flush=True)

if __name__=='__main__':
    main()
