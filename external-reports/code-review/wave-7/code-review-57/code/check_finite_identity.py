"""Optional independent algebraic identity check; requires SymPy.
Does NOT load Asymptotic, Wolfram, or Mathics. Public reachability is unproved.
"""
import json
import sympy as sp

z=sp.sqrt(3)-2
t=sp.symbols('t')
a=sp.symbols('a',positive=True)
f=1/(1-t)
moments=[]
for k in range(4):
    moments.append(sp.simplify(f.subs(t,z)))
    f=sp.cancel(t*sp.diff(f,t))
poly=sp.expand(sum(sp.binomial(3,k)*a**(3-k)*moments[k] for k in range(4)))
expected=(sp.Rational(1,2)+sp.sqrt(3)/6)*a**3-a**2/2-sp.sqrt(3)*a/6
if moments[3] != 0 or sp.simplify(poly-expected) != 0:
    raise SystemExit('Identity check failed')
print(json.dumps({'moments':[str(v) for v in moments], 'lerch_polynomial':str(poly),
                  'zero_constant_moment':True, 'polynomial_identity':True,
                  'scope':'Independent symbolic identity; no package or public-dispatch execution'},indent=2))
