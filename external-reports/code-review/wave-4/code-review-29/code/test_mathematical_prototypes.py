"""Exact formal checks and numerical experiments; not executions of the WL package."""
from __future__ import annotations
import dataclasses,json,sys,time,unittest
from pathlib import Path
import mpmath
import sympy as sp
from gamma_inverse_jet import R,a,q,ZERO,JetAlgebra,newton,triangular,evaluate_gamma_inverse
from lambert_minus_one import from_log_excess,stable_phase
BASE=Path(__file__).resolve().parents[1]
DATA={'Gamma':[],'Lambert':[]}

class MathematicalTests(unittest.TestCase):
    def test_gamma_formal_methods_and_residuals(self):
        for n in (0,1,2,4,6,8):
            start=time.perf_counter();seq,s1=triangular(n);elapsed_seq=time.perf_counter()-start
            start=time.perf_counter();nw,s2=newton(n);elapsed_nw=time.perf_counter()-start
            self.assertEqual(seq,nw)
            residual,_=JetAlgebra().phase(nw,n+1)
            self.assertTrue(all(c==ZERO for c in residual))
            DATA['Gamma'].append({'Order':n,'MethodsAgree':True,'FormalResidualZero':True,
                'TriangularCounts':dataclasses.asdict(s1),'NewtonCounts':dataclasses.asdict(s2),
                'TriangularPythonSeconds':elapsed_seq,'NewtonPythonSeconds':elapsed_nw,
                'CoefficientMonomials':sum(len(c) for c in nw)})

    def test_gamma_leading_coefficients(self):
        u,_=newton(3)
        u2=-q*(6*a*a-6*a+1)/12
        u3=q*((R.one/2-a)*u2+a*(a-1)*(2*a-1)/12)
        self.assertEqual(u[1],a)
        self.assertEqual(u[2],u2)
        self.assertEqual(u[3],u3)
        DATA['GammaCoefficients']=[str(x.as_expr()) for x in u]

    def test_gamma_independent_sympy_expression(self):
        n=4;t=sp.Symbol('t');aa,qq=sp.symbols('a q')
        coeff,_=newton(n)
        U=sum(c.as_expr()*t**j for j,c in enumerate(coeff))
        # Independent SymPy expansion of the displayed defining equation.
        expr=(U+qq*((1+U)*sp.log(1+U)-U)-aa*t-qq*t*sp.log(1+U)/2
              +sum(qq*sp.bernoulli(2*k)*t**(2*k)*(1+U)**(1-2*k)
                   /(2*k*(2*k-1)) for k in range(1,n//2+1)))
        self.assertEqual(sp.expand(sp.series(expr,t,0,n+1).removeO()),0)
        DATA['IndependentSympyOrder']=n

    def test_gamma_original_function_numerics(self):
        ctx=mpmath.mp.clone();ctx.dps=90
        numerical=[]
        for z in (20,50,100):
            target=ctx.mpf(z)*(ctx.log(z)-1)
            root=ctx.findroot(lambda x:ctx.loggamma(x)-target,(z,z+1))
            errors=[]
            for n in (1,2,4,6,8):
                c,_=newton(n);x=evaluate_gamma_inverse(z,c,ctx)
                err=abs(x-root);errors.append(err)
                numerical.append({'Core':z,'Order':n,'AbsoluteError':ctx.nstr(err,25),
                                  'LogGammaResidual':ctx.nstr(ctx.loggamma(x)-target,25)})
            self.assertTrue(all(errors[j+1]<errors[j] for j in range(len(errors)-1)))
        DATA['GammaNumerical']=numerical

    def test_lambert_brackets_and_high_precision_reference(self):
        ref=mpmath.mp.clone();ref.dps=200
        for value in ('0','1e-60','1e-12','0.1','1','10','1000','1000000'):
            r=from_log_excess(value,70)
            d=ref.mpf(value);z=-ref.exp(-1-d)
            w=ref.re(ref.lambertw(z,-1))
            err=abs(ref.mpf(r.value)-w)
            scale=abs(w+1) if d else ref.mpf(1)
            self.assertLess(err,ref.mpf('1e-70')*scale)
            if d:
                L=ref.sqrt(2*d);H=d+ref.sqrt(d*d+2*d)
                self.assertLessEqual(stable_phase(L,ref),d)
                self.assertGreaterEqual(stable_phase(H,ref),d)
            DATA['Lambert'].append({'Delta':value,'RelativeCorrectionError':ref.nstr(err/scale,25),
                'Iterations':r.iterations,'WorkingDigits':r.working_digits,
                'Value':ref.nstr(r.value,90),'Correction':ref.nstr(r.correction,90),
                'LogEquationResidual':ref.nstr(r.log_equation_residual,25),'Certified':r.certified})

    def test_lambert_invalid_arguments(self):
        for x in ('-1','nan','inf'):
            with self.assertRaises(ValueError):from_log_excess(x)
        with self.assertRaises(TypeError):from_log_excess(0.1)
        with self.assertRaises(ValueError):from_log_excess('1',0)
        with self.assertRaises(ArithmeticError):from_log_excess('1',70,max_iterations=1)

if __name__=='__main__':
    result=unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(MathematicalTests))
    DATA.update(Python=sys.version,SymPy=sp.__version__,mpmath=mpmath.__version__,
                TestsRun=result.testsRun,Failures=len(result.failures),Errors=len(result.errors),
                Evidence='Independent exact formal algebra and non-certified numerical experiments')
    (BASE/'results/mathematical-tests.json').write_text(json.dumps(DATA,indent=2)+'\n')
    raise SystemExit(not result.wasSuccessful())
