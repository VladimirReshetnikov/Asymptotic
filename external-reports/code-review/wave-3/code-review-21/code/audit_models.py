"""Independent contract models, NOT a Wolfram Language evaluator.

These intentionally small models isolate dispatch, precision and dependency
invariants. Their passing tests are not tests of the upstream package.
"""
from __future__ import annotations
from dataclasses import dataclass
from fractions import Fraction
from typing import Optional, Iterable

BACKENDS = frozenset({'Automatic', 'Package', 'Series', 'Asymptotic'})


def backend_choice(default: str, explicit: Iterable[str] = (), *, legacy: bool = False) -> str:
    values = tuple(explicit)
    value = values[0] if values else ('Automatic' if legacy else default)
    if value not in BACKENDS:
        raise ValueError('InvalidBackend')
    return value


@dataclass(frozen=True)
class OptionKey:
    """None context denotes a string; a nonempty context denotes a symbol."""
    name: str
    context: Optional[str] = None

    def canonical(self) -> str:
        # Represents OptionValue's documented name equivalence, not evaluation.
        return self.name


@dataclass(frozen=True)
class Expr:
    head: str
    args: tuple['Expr', ...] = ()

    def contains(self, head: str) -> bool:
        return self.head == head or any(x.contains(head) for x in self.args)


def protected_source(expr: Expr, keys: Iterable[OptionKey] = (), *, legacy: bool = False) -> bool:
    always = ('InverseFunction', 'ConditionalExpression', 'GeneralizedSeries', 'PowerLogRemainder')
    if any(expr.contains(h) for h in always):
        return True
    if (expr.contains('Function') if legacy else expr.head in ('Function', 'forwardCallable')):
        return True
    return any(k.canonical() in {'Direction', 'MaxTerms', 'InverseFunctionBranches'} for k in keys)


class UnknownCoefficient(LookupError):
    pass


@dataclass(frozen=True)
class NativeTaylor:
    """Ordinary integer-lattice jet; endpoint is EXCLUSIVE, not exactness."""
    first: int
    endpoint: int
    coefficients: tuple[Fraction, ...]

    def __post_init__(self) -> None:
        if self.first < 0 or self.endpoint < self.first:
            raise ValueError('not a regular Taylor jet')
        if len(self.coefficients) > self.endpoint - self.first:
            raise ValueError('coefficient crosses unknown frontier')

    def coefficient(self, k: int, *, legacy_zero_fill: bool = False) -> Fraction:
        if k < 0:
            raise ValueError('nonnegative coefficient index required')
        if k >= self.endpoint and not legacy_zero_fill:
            raise UnknownCoefficient(k)
        i = k - self.first
        return self.coefficients[i] if 0 <= i < len(self.coefficients) else Fraction(0)

    def covers_request(self, requested_coefficient: int) -> bool:
        return self.endpoint > requested_coefficient


def compose_identity(taylor: NativeTaylor, cutoff: int, *, legacy: bool = False) -> dict[int, Fraction]:
    """Compose with eta(x)=x, with zero filling or with explicit frontier checks."""
    if cutoff < 1:
        raise ValueError('positive cutoff required in this model')
    if not legacy and not taylor.covers_request(cutoff):
        raise UnknownCoefficient('requested Taylor probe was incomplete')
    return {k: c for k in range(cutoff)
            if (c := taylor.coefficient(k, legacy_zero_fill=legacy)) != 0}


@dataclass(frozen=True)
class DerivedJet:
    retained_powers: tuple[Fraction, ...]
    exact: bool
    kind: str = 'Derived'
    ordinary_representation: bool = True

    def exact_noop(self, cutoff: Fraction, limit: int = 20_000) -> bool:
        if not isinstance(limit, int) or isinstance(limit, bool) or limit < 1:
            raise ValueError('InvalidOption')
        return (self.kind == 'Derived' and self.ordinary_representation and self.exact
                and (not self.retained_powers or max(self.retained_powers) < cutoff))


def replay_constant(cutoff: Fraction, ancestor_cap: Fraction, *, optimized: bool = False) -> tuple[Fraction, int]:
    constant = DerivedJet((Fraction(0),), True)
    if optimized and constant.exact_noop(cutoff):
        return Fraction(7), 0
    # Models the recipe's positive-valuation operand guard margin, h + 2.
    demanded = cutoff + 2
    if demanded > ancestor_cap:
        raise UnknownCoefficient('InsufficientInputOrder in irrelevant ancestor')
    return Fraction(7), 1
