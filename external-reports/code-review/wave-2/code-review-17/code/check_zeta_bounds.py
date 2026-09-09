#!/usr/bin/env python3
"""Independent numerical checks of the proved fixed-order Zeta tail bound.
These are high-precision spot checks, not certified inequalities.
"""
import json
from pathlib import Path
import mpmath as mp

mp.mp.dps = 70
rows=[]
for m in (2,4,8):
    for s in (3,10):
        for j in range(5):
            ell=mp.log(m)
            if s*ell < j: continue
            def tail(t):
                return mp.zeta(t)-mp.fsum(mp.power(n,-t) for n in range(1,m))
            actual=(-1)**j*mp.diff(tail,mp.mpf(s),j)
            bound=mp.power(m,-s)*ell**j+mp.power(m,1-s)*mp.fsum(
                mp.factorial(j)/mp.factorial(j-k)*ell**(j-k)/mp.power(s-1,k+1)
                for k in range(j+1))
            assert actual > 0 and actual <= bound
            rows.append({'m':m,'s':s,'j':j,'tail_derivative':mp.nstr(actual,25),
                         'upper_bound':mp.nstr(bound,25),
                         'ratio':mp.nstr(actual/bound,20)})
output={'scope':'Independent numerical spot checks, not native Wolfram tests or certificates',
        'working_decimal_digits':70,'cases_passed':len(rows),'cases':rows}
p=Path(__file__).resolve().parents[1]/'evidence'/'zeta_bound_results.json'
p.write_text(json.dumps(output,indent=2)+'\n')
print(f"Zeta derivative bound: {len(rows)} cases passed at 70 decimal digits.")
