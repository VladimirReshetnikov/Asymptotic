"""Regenerate the article's independent numerical tables; no upstream execution."""
from pathlib import Path
import csv, json
import mpmath as mp
from uniform_lerch import make_model

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'evidence'
ARTICLE = ROOT / 'article'
EVIDENCE.mkdir(exist_ok=True)
ARTICLE.mkdir(exist_ok=True)

with mp.workdps(90):
    rows = []
    for v in (16, 64, 256, 1024):
        vv = mp.mpf(v); L = mp.log(vv)
        g = -mp.sqrt(vv) + L/(4*mp.sqrt(vv))
        b = (-mp.mpf(1)/4+L/8-L**2/32)/vv**mp.mpf('1.5')
        root = mp.findroot(lambda z: mp.log(mp.erfc(z))+vv+mp.log(mp.pi)/2, -g)
        error = -root-g
        rows.append([v, mp.nstr(error/(-b), 16),
                     mp.nstr(abs(error-b)/abs(error), 16),
                     mp.nstr(abs(error+b)/abs(error), 16)])
    with (EVIDENCE/'erfc-reflection-numerics.csv').open('w', newline='') as f:
        w=csv.writer(f); w.writerow(['v','actual_error_over_correct_frontier','wrong_correction_error_over_old_error','fixed_correction_error_over_old_error']); w.writerows(rows)
    with (ARTICLE/'erfc-table.tex').open('w') as f:
        for v,e,w,c in rows:
            f.write(f'{v} & {float(e):.6f} & {float(w):.6f} & {float(c):.6f} \\\\\n')
    rows=[]
    for a in (5, 10, 50, 100):
        truth=mp.lerchphi(mp.exp(-mp.mpf(1)/a),2,a)
        for k in (0,1,2):
            model=make_model(1,2,k); d=model.numerical(a,dps=90)
            err=truth-d['approximation']; ratio=model.remainder_sign*err/d['analytic_bound_value']
            rows.append([a,k,mp.nstr(err,18),mp.nstr(d['analytic_bound_value'],18),mp.nstr(ratio,18)])
    with (EVIDENCE/'uniform-lerch-numerics.csv').open('w',newline='') as f:
        w=csv.writer(f);w.writerow(['a','K','signed_error','absolute_analytic_bound','signed_error_over_bound']);w.writerows(rows)
    def sci(x):
        x=mp.mpf(x)
        if x==0:return '0'
        exponent=int(mp.floor(mp.log10(abs(x))))
        mantissa=x/mp.power(10,exponent)
        return f'{float(mantissa):.4f}\\times 10^{{{exponent}}}'
    with (ARTICLE/'lerch-table.tex').open('w') as f:
        for a,k,e,b,r in rows:
            f.write(f'{a} & {k} & ${sci(e)}$ & ${sci(b)}$ & {float(r):.6f} \\\\\n')
    example=make_model(1,2,2)
    (EVIDENCE/'uniform-lerch-example.json').write_text(json.dumps(example.exact_description(),indent=2)+'\n')
print('Regenerated two numerical tables and the exact model description.')
