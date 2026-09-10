"""Stage the narrowly scoped Dirichlet goal fix; never edit the source in place.

Usage:
  python patch_dirichlet_goals.py /path/to/Asymptotic /path/to/staged-output

Writes only the edited canonical module and a unified diff. Rebuild the root
standalone in a disposable checkout using the repository's own builder.
Anchor guards reject a changed or already-patched source. No checksum files.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

RELATIVE = Path("src/Kernel/DirichletSpecialFunctions.wl")
REPLACEMENTS = (
    ('If[less[Log[limit + 1], cut], fail["ResourceLimit", "The Zeta exponential-coordinate cutoff exceeds MaxTerms."]];',
     'If[less[Log[limit + 1], cut] && (goal === Automatic || goal > limit), fail["ResourceLimit", "The Zeta exponential-coordinate cutoff exceeds MaxTerms."]];'),
    ('low = 0; high = limit + 1;',
     'low = 0; high = If[goal === Automatic, limit + 1, Min[limit, goal] + 1];'),
    ('If[If[cut === Automatic, Length[rows] >= goal, ! less[s + k, cut]],',
     'If[(cut =!= Automatic && ! less[s + k, cut]) || (goal =!= Automatic && Length[rows] >= goal),'),
)


def patch_text(text: str) -> str:
    for old, _ in REPLACEMENTS:
        count = text.count(old)
        if count != 1:
            raise ValueError(f"expected exactly one anchor, found {count}: {old}")
    for old, new in REPLACEMENTS:
        text = text.replace(old, new, 1)
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    source = (args.repository / RELATIVE).resolve()
    destination = (args.output / RELATIVE).resolve()
    if source == destination:
        parser.error("output must not be the source repository")
    original = source.read_text(encoding="utf-8")
    edited = patch_text(original)  # Validate every anchor before writing.
    diff = "".join(difflib.unified_diff(original.splitlines(True), edited.splitlines(True),
                                      fromfile="a/" + RELATIVE.as_posix(),
                                      tofile="b/" + RELATIVE.as_posix()))
    patch_path = (args.output / "dirichlet-goals.patch").resolve()
    if destination.exists() or patch_path.exists():
        parser.error("refusing to overwrite existing staged artifacts")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(edited, encoding="utf-8")
    patch_path.write_text(diff, encoding="utf-8")
    print(f"Staged canonical module: {destination}")
    print(f"Unified diff: {patch_path}")


if __name__ == "__main__":
    main()
