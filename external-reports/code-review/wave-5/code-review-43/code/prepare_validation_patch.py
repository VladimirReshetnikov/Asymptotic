"""Emit (do not apply) the F03 two-file candidate patch against a local checkout.

Usage: python prepare_validation_patch.py /path/to/Asymptotic > validation.patch
This verifies exact old fragments and changes no repository files. Rebuild the
standalone package using the repository's existing builder after accepting it.
Native and Mathics integration tests have not been executed for this patch.
"""
from pathlib import Path
import argparse
import difflib
import sys

OLD_TEST = 'If[x === y || ! FreeQ[h, y],'
NEW_TEST = 'If[x === y || ! FreeQ[h, y] || ! FreeQ[phi, x],'
OLD_MESSAGE = 'Use distinct symbols; h must not contain y.'
NEW_MESSAGE = 'Use distinct symbols; h must not contain y and phi must not contain x.'
PATHS = ('src/Kernel/AsymptoticAnalysis.wl', 'src/Kernel/MathicsCalculus.wl')


def candidate_patch(root: Path) -> str:
    diffs = []
    for relative in PATHS:
        path = root / relative
        before = path.read_text(encoding='utf-8')
        if before.count(OLD_TEST) != 1 or before.count(OLD_MESSAGE) != 1:
            raise ValueError(f'{relative}: exact baseline fragments are not unique; no patch emitted')
        after = before.replace(OLD_TEST, NEW_TEST).replace(OLD_MESSAGE, NEW_MESSAGE)
        diffs.extend(difflib.unified_diff(before.splitlines(keepends=True),
            after.splitlines(keepends=True), fromfile='a/'+relative, tofile='b/'+relative))
    return ''.join(diffs)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('checkout', type=Path)
    args = parser.parse_args()
    try:
        patch = candidate_patch(args.checkout)
    except (OSError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    sys.stdout.write(patch)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
