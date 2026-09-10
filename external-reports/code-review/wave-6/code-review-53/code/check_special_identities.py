"""Independent numerical spot checks of inspected source formulas.

No package execution. These are numerical controls, NOT proof certificates.
Requires mpmath (tested with 1.3.0). The rational certificate tests do not.
"""
import json
from pathlib import Path
import mpmath as mp
mp.mp.dps = 120
counts = {"half_integer_bessel": 0, "terminating_hypergeometric_u": 0,
          "incomplete_gamma_frobenius": 0, "lerch_tail_bounds": 0}
worst = mp.mpf(0)

def compare(a, b, family):
    global worst
    err = abs(a-b)/max(1,abs(a),abs(b))
    worst = max(worst,err)
    assert err < mp.mpf('1e-80'), (family,err)
    counts[family] += 1

def khalf(n,z):
    return mp.sqrt(mp.pi/2)*mp.exp(-z)/mp.sqrt(z)*sum(
        mp.factorial(n+k)/(mp.factorial(k)*mp.factorial(n-k)*(2*z)**k)
        for k in range(n+1))

for n in range(9):
    for z in map(mp.mpf,['0.25','1','3','10']):
        previous=(mp.exp(z)+mp.exp(-z))/2
        current=(mp.exp(z)-mp.exp(-z))/2
        for k in range(1,n+1):
            previous,current=current,previous-(2*k-1)*current/z
        pos=mp.sqrt(2/mp.pi)*current/mp.sqrt(z)
        neg=pos+2*(-1)**n/mp.pi*khalf(n,z)
        nu=n+mp.mpf('0.5')
        compare(pos,mp.besseli(nu,z),'half_integer_bessel')
        compare(neg,mp.besseli(-nu,z),'half_integer_bessel')
        compare(khalf(n,z),mp.besselk(nu,z),'half_integer_bessel')

for n in range(9):
    for b in map(mp.mpf,['0.5','2.5','-0.75']):
        for z in map(mp.mpf,['0.3','2','5']):
            p=sum((-1)**(n+k)*mp.binomial(n,k)*mp.rf(b+k,n-k)*z**k
                  for k in range(n+1))
            compare(p,mp.hyperu(-n,b,z),'terminating_hypergeometric_u')

for a in [mp.mpf('0.5'),mp.sqrt(2),mp.mpf('2.5')]:
    for z in map(mp.mpf,['0.01','0.3','2']):
        lower=z**a*mp.hyp1f1(a,a+1,-z)/a
        compare(mp.gamma(a)-lower,mp.gammainc(a,z,mp.inf),'incomplete_gamma_frobenius')
        fixed=mp.mpf('1.25')
        other=fixed**a*mp.hyp1f1(a,a+1,-fixed)/a
        compare(other-lower,mp.gammainc(a,z,fixed),'incomplete_gamma_frobenius')
        compare(lower-other,mp.gammainc(a,fixed,z),'incomplete_gamma_frobenius')

# Direct convergent defining sum is independent of the moment formula.
# 600 terms with |z| <= 1/2 make the omitted numerical reference tail tiny;
# these comparisons still remain numerical tests rather than certificates.
def moment(z,k):
    return 1/(1-z) if k==0 else mp.polylog(-k,z)

for z in map(mp.mpf,['0.5','-0.5','0.2']):
    for s in [mp.mpf('-2.5'),mp.mpf(1)/3,mp.sqrt(2),mp.mpf(-3)]:
        for a in map(mp.mpf,['1','3','10']):
            exact=sum(z**n/(a+n)**s for n in range(600))
            for N in [0,1,2,4]:
                approximation=sum((-1)**k*mp.rf(s,k)*moment(z,k)/mp.factorial(k)*a**(-s-k)
                                  for k in range(N))
                d=max(0,int(mp.ceil(-s-N)))
                constant=abs(mp.rf(s,N))/mp.factorial(N)*sum(
                    mp.binomial(d,j)*moment(abs(z),N+j) for j in range(d+1))
                bound=constant*a**(-s-N)
                assert abs(exact-approximation) <= bound+mp.mpf('1e-80')*max(1,abs(exact))
                counts['lerch_tail_bounds'] += 1

result={"scope":"independent numerical controls, not Wolfram/Mathics execution",
        "mpmath_version":mp.__version__,"decimal_working_precision":mp.mp.dps,
        "counts":counts,"total":sum(counts.values()),
        "largest_scaled_identity_discrepancy":mp.nstr(worst,15),"passed":True}
print(json.dumps(result,indent=2))
