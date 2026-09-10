"""Independent reference models for the AsymptoticAnalysis differential audit.

These are not an implementation of Wolfram Language or of Mathics. In particular,
option handling below models only the documented/source-inspected cases used in
this audit. Graded-tail routines use exact rational algebraic exponents.
"""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from math import factorial
from typing import Callable, Iterable, Iterator, Sequence, TypeAlias


@dataclass(frozen=True)
class SymbolKey:
    name: str
    context: str = "System`"


@dataclass(frozen=True)
class Rule:
    key: str | SymbolKey
    value: object
    delayed: bool = False

    def resolve(self) -> object:
        if self.delayed:
            if not callable(self.value):
                raise TypeError("The model represents a delayed value by a callable")
            return self.value()
        return self.value


OptionTree: TypeAlias = Rule | list["OptionTree"] | tuple["OptionTree", ...]


def option_leaves(tree: OptionTree) -> Iterator[Rule]:
    """Flatten option containers, never a rule's value."""
    if isinstance(tree, Rule):
        yield tree
    elif isinstance(tree, (list, tuple)):
        for item in tree:
            yield from option_leaves(item)
    else:
        raise TypeError(f"Invalid option tree leaf: {type(tree).__name__}")


def option_key_name(key: str | SymbolKey) -> str:
    return key.name if isinstance(key, SymbolKey) else key


def desired_power(options: OptionTree, stored: object) -> object:
    """First matching option wins; the stored power is only an omitted default."""
    for rule in option_leaves(options):
        if option_key_name(rule.key) == "Power":
            return rule.resolve()
    return stored


def inspected_power_selection(
    options: Sequence[OptionTree], stored: object, *, evaluator: str
) -> object:
    """Small control-flow model of the inspected FilterRules / ReplaceAll pair.

    Wolfram mode uses its string-pattern/symbol-name convenience and its
    natively observed flattening of nested rule lists.
    Mathics mode models the 10.0.1 FilterRules loop: top-level Rule only, literal
    matching in these test cases. This function is NOT a native observation.
    """
    if evaluator not in {"wolfram", "mathics"}:
        raise ValueError("Unknown modeled evaluator")
    selected = []
    items = option_leaves(list(options)) if evaluator == "wolfram" else iter(options)
    for item in items:
        if not isinstance(item, Rule):
            continue
        if evaluator == "wolfram":
            match = option_key_name(item.key) == "Power"
        else:
            match = not item.delayed and item.key == "Power"
        if match:
            selected.append(item)
    if not selected:
        return stored
    # ReplaceAll acts on the literal string, not on option-name equivalence.
    for rule in selected:
        if rule.key == "Power":
            return rule.resolve()
    return "Power"


def inverse_unit_coefficient(power: int, index: int) -> Fraction:
    """[y^index] (g(y)/y)^power, where g+g^2=y and g/y -> 1.

    Polynomial-in-power form avoids the removable singularity in the usual
    r/(r+k) binomial formula when r+k=0.
    """
    if index < 0:
        raise ValueError("A coefficient index must be nonnegative")
    if index == 0:
        return Fraction(1)
    product = power
    for j in range(index + 1, 2 * index):
        product *= power + j
    return Fraction((-1) ** index * product, factorial(index))


@dataclass(frozen=True)
class Bound:
    power: Fraction
    log_degree: int = 0

    def __post_init__(self) -> None:
        if not isinstance(self.power, Fraction):
            object.__setattr__(self, "power", Fraction(self.power))
        if self.log_degree < 0:
            raise ValueError("Logarithmic degrees must be nonnegative")


@dataclass(frozen=True)
class Candidate:
    grade: int
    bound: Bound

    def __post_init__(self) -> None:
        if self.grade < 0:
            raise ValueError("Exponential grades must be nonnegative")


Tail: TypeAlias = Candidate | None  # None denotes an exact zero bound.


def add_bounds(a: Bound, b: Bound) -> Bound:
    if a.power < b.power:
        return a
    if b.power < a.power:
        return b
    return Bound(a.power, max(a.log_degree, b.log_degree))


def multiply_bounds(a: Bound, b: Bound) -> Bound:
    return Bound(a.power + b.power, a.log_degree + b.log_degree)


def join_tails(a: Tail, b: Tail) -> Tail:
    if a is None:
        return b
    if b is None:
        return a
    if a.grade < b.grade:
        return a
    if b.grade < a.grade:
        return b
    return Candidate(a.grade, add_bounds(a.bound, b.bound))


def materialized_tail(candidates: Iterable[Candidate]) -> Tail:
    items = list(candidates)
    if not items:
        return None
    grade = min(item.grade for item in items)
    answer = None
    for item in items:
        if item.grade == grade:
            answer = join_tails(answer, item)
    return answer


def two_pass_tail(factory: Callable[[], Iterable[Candidate]]) -> Tail:
    """Constant auxiliary result storage; the factory must be pure/repeatable.

    Pass 1 compares only integer grades. Thus an algebraic comparison at a
    temporary, ultimately dominated grade is never required. The production
    integration can also make bound construction lazy after finding the grade.
    """
    least: int | None = None
    for item in factory():
        if least is None or item.grade < least:
            least = item.grade
    if least is None:
        return None
    answer = None
    for item in factory():
        if item.grade == least:
            answer = join_tails(answer, item)
    return answer


def candidate_count_equal_depth(n: int) -> int:
    """All coefficients nonzero, finite input tails, nonzero first omitted sum."""
    if n < 1:
        raise ValueError("This audit's flat inverse depth is at least one")
    return n * (n - 1) // 2 + 2 * (n + 1) + 2


def dense_flat_candidates(n: int) -> Iterator[Candidate]:
    """Synthetic candidates with the same grade population as the inspected loop.

    Algebraic powers are illustrative exact values, not package coefficients.
    """
    if n < 1:
        raise ValueError("Depth must be positive")
    for i in range(n + 1):
        for j in range(n + 1):
            if i + j > n + 1:
                yield Candidate(i + j, Bound(Fraction(-i - j), (i + j) % 3))
    # Complete first omitted coefficient, assumed nonzero in this count model.
    yield Candidate(n + 1, Bound(Fraction(1 - 2 * n), 0))
    for j in range(n + 1):
        yield Candidate(n + 1 + j, Bound(Fraction(-2 * n - j), j % 2))
    for i in range(n + 1):
        yield Candidate(n + 1 + i, Bound(Fraction(-2 * n - i), i % 2))
    yield Candidate(2 * n + 2, Bound(Fraction(-4 * n), 0))


def local_observation(u: Fraction, side: int, power: int) -> dict[str, Fraction | int]:
    if u <= 0 or side not in (-1, 1) or power == 0:
        raise ValueError("Require u>0, side=+/-1, and a nonzero integer power")
    reference = u if power == 1 else (side * u) ** power
    return {"LocalRoot": u, "LocalApproximation": reference,
            "LocalReferenceObservable": reference, "ObservablePower": power}
