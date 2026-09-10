"""Exact whole-real-line monotonicity certificates for rational polynomials.

The checker uses only Python's standard library and exact Fraction arithmetic.
The optional producer uses SymPy for square-free factorization; its answers are
not trusted by the checker. Input is a coefficient list in ascending powers,
not an expression string. No arbitrary code or symbolic input is evaluated.

Scope: nonconstant polynomials over Q on all of R. This does not establish a
positive derivative lower bound, a Lipschitz inverse, or an asymptotic tail.
"""
from __future__ import annotations
from fractions import Fraction
from typing import Any, Dict, List, Sequence, Tuple
import argparse
import json
import re

Poly = Tuple[Fraction, ...]
MAX_DEGREE = 64
MAX_BITS = 4096
MAX_JSON_BYTES = 250_000


class CertificateError(ValueError):
    pass


def poly(values: Sequence[Any]) -> Poly:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_DEGREE + 1:
        raise CertificateError("Invalid polynomial length")
    result = []
    for value in values:
        if isinstance(value, bool) or not isinstance(value, (str, int, Fraction)):
            raise CertificateError("Coefficients must be exact rational strings or integers")
        if isinstance(value, str):
            if len(value) > 2600 or re.fullmatch(r"[+-]?[0-9]+(?:/[+-]?[0-9]+)?", value) is None:
                raise CertificateError("Use a bounded integer or numerator/denominator string")
        q = Fraction(value)
        if max(q.numerator.bit_length(), q.denominator.bit_length()) > MAX_BITS:
            raise CertificateError("Coefficient bit limit exceeded")
        result.append(q)
    while len(result) > 1 and result[-1] == 0:
        result.pop()
    return tuple(result)


def checked(values: Sequence[Fraction]) -> Poly:
    return poly(list(values))


ZERO = (Fraction(0),)
ONE = (Fraction(1),)


def degree(p: Poly) -> int:
    return len(p) - 1


def add(a: Poly, b: Poly) -> Poly:
    out = [Fraction(0)] * max(len(a), len(b))
    for i, q in enumerate(a): out[i] += q
    for i, q in enumerate(b): out[i] += q
    return checked(out)


def neg(a: Poly) -> Poly:
    return tuple(-q for q in a)


def mul(a: Poly, b: Poly) -> Poly:
    if a == ZERO or b == ZERO:
        return ZERO
    if degree(a) + degree(b) > MAX_DEGREE:
        raise CertificateError("Polynomial degree limit exceeded")
    out = [Fraction(0)] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] += x * y
    return checked(out)


def power(a: Poly, n: int) -> Poly:
    if isinstance(n, bool) or not isinstance(n, int) or not 0 <= n <= MAX_DEGREE:
        raise CertificateError("Invalid factor multiplicity")
    if degree(a) * n > MAX_DEGREE:
        raise CertificateError("Powered degree limit exceeded")
    out, base = ONE, a
    while n:
        if n & 1: out = mul(out, base)
        n //= 2
        if n: base = mul(base, base)
    return out


def derivative(a: Poly) -> Poly:
    return checked([i * a[i] for i in range(1, len(a))] or [Fraction(0)])


def remainder(a: Poly, b: Poly) -> Poly:
    if b == ZERO:
        raise CertificateError("Division by zero polynomial")
    r = a
    while r != ZERO and degree(r) >= degree(b):
        shift, coefficient = degree(r) - degree(b), r[-1] / b[-1]
        out = list(r)
        for j, q in enumerate(b): out[j + shift] -= coefficient * q
        r = checked(out)
    return r


def sturm_chain(p: Poly) -> List[Poly]:
    if p == ZERO:
        raise CertificateError("The zero polynomial has no finite root count")
    if degree(p) == 0:
        return [p]
    chain = [p, derivative(p)]
    while True:
        r = neg(remainder(chain[-2], chain[-1]))
        if r == ZERO:
            return chain
        chain.append(r)
        if len(chain) > MAX_DEGREE + 1:
            raise CertificateError("Sturm chain exceeds degree limit")


def variations(signs: Sequence[int]) -> int:
    nz = [s for s in signs if s]
    return sum(a != b for a, b in zip(nz, nz[1:]))


def infinity_sign(p: Poly, direction: int) -> int:
    if p == ZERO:
        return 0
    s = 1 if p[-1] > 0 else -1
    return s if direction == 1 or degree(p) % 2 == 0 else -s


def whole_line_root_count(chain: Sequence[Poly]) -> int:
    return (variations([infinity_sign(p, -1) for p in chain]) -
            variations([infinity_sign(p, 1) for p in chain]))


def encoded(p: Poly) -> List[str]:
    return [str(q) for q in p]


def verify_certificate(record: Dict[str, Any]) -> Dict[str, Any]:
    """Recheck all identities and signs. Malformed or over-budget means rejection."""
    try:
        if not isinstance(record, dict):
            raise CertificateError("Certificate must be an object")
        if len(json.dumps(record).encode("utf-8")) > MAX_JSON_BYTES:
            raise CertificateError("Certificate byte limit exceeded")
        if record.get("schema") != "RationalPolynomialMonotonicity/1":
            raise CertificateError("Unsupported schema")
        if record.get("domain") != "R":
            raise CertificateError("Only the whole real line is supported")
        f = poly(record["function"])
        q = derivative(f)
        if q == ZERO:
            raise CertificateError("A constant polynomial is not strictly monotone")
        if q != poly(record["derivative"]):
            raise CertificateError("Derivative identity failed")
        cpoly = poly([record["factor_coefficient"]])
        if cpoly == ZERO:
            raise CertificateError("Zero factor coefficient")
        factors = record["factors"]
        if not isinstance(factors, list) or len(factors) > MAX_DEGREE:
            raise CertificateError("Invalid factor list")
        reconstructed, odd = cpoly, ONE
        total_degree = 0
        for item in factors:
            fct, m = poly(item["polynomial"]), item["multiplicity"]
            if degree(fct) < 1:
                raise CertificateError("Constant factor")
            if isinstance(m, bool) or not isinstance(m, int) or not 1 <= m <= MAX_DEGREE:
                raise CertificateError("Invalid factor multiplicity")
            total_degree += degree(fct) * m
            if total_degree > MAX_DEGREE:
                raise CertificateError("Factor product degree exceeds limit")
            reconstructed = mul(reconstructed, power(fct, m))
            if m % 2:
                odd = mul(odd, fct)
        if reconstructed != q:
            raise CertificateError("Factorization identity failed")
        if odd != poly(record["odd_part"]):
            raise CertificateError("Odd-part identity failed")
        raw_chain = record["odd_part_sturm"]
        if not isinstance(raw_chain, list) or len(raw_chain) > MAX_DEGREE + 1:
            raise CertificateError("Invalid Sturm chain length")
        supplied_chain = [poly(p) for p in raw_chain]
        chain = sturm_chain(odd)
        if supplied_chain != chain:
            raise CertificateError("Sturm recurrence failed")
        roots = whole_line_root_count(chain)
        if roots != 0 or degree(odd) % 2:
            raise CertificateError("Odd-multiplicity part has a real zero")
        sign = 1 if q[-1] > 0 else -1
        expected = "StrictlyIncreasing" if sign == 1 else "StrictlyDecreasing"
        if record.get("conclusion") != expected:
            raise CertificateError("Claimed direction disagrees with the derivative")
        stationary = whole_line_root_count(sturm_chain(q))
        if record.get("stationary_real_roots") != stationary:
            raise CertificateError("Stationary-root count disagrees")
        return {"accepted": True, "conclusion": expected,
                "stationary_real_roots": stationary,
                "positive_derivative_lower_bound_asserted": False,
                "numeric_inverse_error_bound_asserted": False}
    except (CertificateError, KeyError, TypeError, ValueError, OverflowError, ZeroDivisionError) as exc:
        return {"accepted": False, "reason": str(exc)}


def produce_certificate(coefficients: Sequence[Any]) -> Dict[str, Any]:
    """Optional producer. Nonmonotone and constant inputs return an inconclusive record."""
    import sympy as sp
    f = poly(coefficients)
    q = derivative(f)
    if q == ZERO:
        return {"status": "NoCertificate", "reason": "ConstantPolynomial"}
    x = sp.Symbol("x")
    expression = sum(sp.Rational(v.numerator, v.denominator) * x ** i for i, v in enumerate(q))
    c, facs = sp.sqf_list(sp.Poly(expression, x, domain=sp.QQ))
    factors, odd = [], ONE
    for factor, m in facs:
        values = poly([str(v) for v in reversed(factor.all_coeffs())])
        factors.append({"polynomial": encoded(values), "multiplicity": int(m)})
        if m % 2: odd = mul(odd, values)
    chain = sturm_chain(odd)
    if whole_line_root_count(chain) != 0:
        return {"status": "NoCertificate", "reason": "DerivativeHasOddMultiplicityRealZero"}
    record = {
        "schema": "RationalPolynomialMonotonicity/1", "domain": "R",
        "function": encoded(f), "derivative": encoded(q),
        "factor_coefficient": str(c), "factors": factors,
        "odd_part": encoded(odd), "odd_part_sturm": [encoded(p) for p in chain],
        "conclusion": "StrictlyIncreasing" if q[-1] > 0 else "StrictlyDecreasing",
        "stationary_real_roots": whole_line_root_count(sturm_chain(q)),
        "scope": "Strict global monotonicity only; no positive slope lower bound or inverse error estimate"
    }
    verification = verify_certificate(record)
    if not verification["accepted"]:
        raise CertificateError("Producer emitted an invalid certificate: " + verification["reason"])
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    make = commands.add_parser("produce")
    make.add_argument("coefficients", help='JSON list in ascending powers, e.g. ["0","1","0","-2/3","0","1/5"]')
    check = commands.add_parser("verify")
    check.add_argument("certificate")
    args = parser.parse_args()
    if args.command == "produce":
        print(json.dumps(produce_certificate(json.loads(args.coefficients)), indent=2))
        return 0
    with open(args.certificate, encoding="utf-8") as stream:
        text = stream.read(MAX_JSON_BYTES + 1)
    if len(text.encode("utf-8")) > MAX_JSON_BYTES:
        print(json.dumps({"accepted": False, "reason": "Certificate byte limit exceeded"}))
        return 1
    result = verify_certificate(json.loads(text))
    print(json.dumps(result, indent=2))
    return 0 if result["accepted"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
