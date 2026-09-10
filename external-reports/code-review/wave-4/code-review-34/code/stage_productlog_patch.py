"""Stage candidate ProductLog methods into a Mathics expintegral.py copy.

This fixes conversion order in both directions and numerical arity/order.
The output has not been integration-tested in a Mathics kernel. It does not
address every ProductLog feature, derivative rule, or invalid-branch policy.
"""
from __future__ import annotations
import argparse
import ast
import inspect
from pathlib import Path
from productlog_bridge import ProductLogOrderMixin


def stage(text: str) -> str:
    tree = ast.parse(text)
    classes = [n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == "ProductLog"]
    if len(classes) != 1:
        raise ValueError("Expected exactly one ProductLog class")
    target = classes[0]
    if not any(isinstance(base, ast.Name) and base.id == "MPMathFunction" for base in target.bases):
        raise ValueError("Unexpected ProductLog base class")
    forbidden = {"prepare_sympy", "from_sympy", "get_mpmath_function", "nargs"}
    defined = {n.name for n in target.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
    for n in target.body:
        if isinstance(n, ast.Assign):
            defined.update(t.id for t in n.targets if isinstance(t, ast.Name))
    if forbidden & defined:
        raise ValueError("Existing bridge methods/arity found; refusing to overwrite another implementation")
    lines = text.splitlines(keepends=True)
    methods = "".join(inspect.getsource(ProductLogOrderMixin).splitlines(keepends=True)[1:])
    lines.insert(target.end_lineno, "\n" + methods + "\n")
    output = "".join(lines)
    # Preserve the module docstring and any future imports.
    parsed = ast.parse(output)
    if not any(isinstance(n, ast.Import) and any(a.name == "mpmath" for a in n.names) for n in parsed.body):
        insert_at = 0
        for n in parsed.body:
            if isinstance(n, ast.Expr) and isinstance(n.value, ast.Constant) and isinstance(n.value.value, str):
                insert_at = n.end_lineno
            elif isinstance(n, ast.ImportFrom) and n.module == "__future__":
                insert_at = n.end_lineno
            else:
                break
        lines = output.splitlines(keepends=True)
        lines.insert(insert_at, "\nimport mpmath\n")
        output = "".join(lines)
    ast.parse(output)
    return output


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("source", type=Path)
    p.add_argument("destination", type=Path)
    a = p.parse_args()
    if a.source.resolve() == a.destination.resolve():
        p.error("Use a different destination; this tool never patches in place")
    result = stage(a.source.read_text(encoding="utf-8"))
    a.destination.parent.mkdir(parents=True, exist_ok=True)
    a.destination.write_text(result, encoding="utf-8")


if __name__ == "__main__":
    main()
