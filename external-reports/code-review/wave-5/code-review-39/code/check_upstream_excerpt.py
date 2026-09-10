#!/usr/bin/env python3
"""Compare the four bundled upstream functions with a supplied local checkout.

This optional source-matching check was not run against a complete checkout in
this review environment. It does not fetch or modify the repository. Function
ASTs are compared without source-location attributes, so comments/formatting do
not matter but executable expressions and diagnostic strings do.
"""
import argparse
import ast
from pathlib import Path

NAMES = {"require", "canonical_sources", "protocol_fields", "validate_shard"}

def functions(path: Path):
    tree = ast.parse(path.read_text(encoding="utf-8"))
    selected = {n.name: ast.dump(n, include_attributes=False) for n in tree.body
                if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)) and n.name in NAMES}
    if set(selected) != NAMES:
        raise ValueError(f"Missing requested function(s) in {path}: {sorted(NAMES-set(selected))}")
    return selected

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path)
    args=parser.parse_args()
    upstream=args.repo/"validation"/"check_mathics_acceptance.py"
    bundled=Path(__file__).with_name("receipt_excerpt.py")
    try:
        a,b=functions(upstream),functions(bundled)
        mismatches=sorted(name for name in NAMES if a[name]!=b[name])
        if mismatches:
            parser.exit(1,"Executable source mismatch: "+", ".join(mismatches)+"\n")
        print("All four function ASTs match the supplied checkout.")
    except (OSError, UnicodeError, SyntaxError, ValueError) as exc:
        parser.exit(2,str(exc)+"\n")

if __name__=="__main__":
    main()
