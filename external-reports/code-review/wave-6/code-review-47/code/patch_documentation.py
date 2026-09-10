"""Emit the narrowly scoped N02/N03 candidate; do not modify the source.

Usage: python patch_documentation.py path/to/check_documentation.py output.py
Place documentation_audit_guards.py alongside the emitted module. The program
refuses changed source shapes rather than silently patching an unrelated file.
"""
from __future__ import annotations
import argparse
import ast
from pathlib import Path

def patched_source(text: str) -> str:
    edits = [
        ('from documentation_text import check_text_encoding',
         'from documentation_text import check_text_encoding\nfrom documentation_audit_guards import require, strip_tex_comments'),
        ('re.findall(r"\\\\input\\{([^}]+)\\}", text)',
         're.findall(r"\\\\input\\{([^}]+)\\}", strip_tex_comments(text))'),
        ('    labels = re.findall',
         '    active_text = strip_tex_comments(text)\n    labels = re.findall'),
        ('r"\\\\label\\{([^}]+)\\}", text)', 'r"\\\\label\\{([^}]+)\\}", active_text)'),
        ('r"\\\\(?:ref|eqref|pageref)\\{([^}]+)\\}", text)',
         'r"\\\\(?:ref|eqref|pageref)\\{([^}]+)\\}", active_text)'),
        ('r"\\\\bibitem\\{([^}]+)\\}", text)', 'r"\\\\bibitem\\{([^}]+)\\}", active_text)'),
        ('r"\\\\cite(?:\\[[^]]*\\])?\\{([^}]+)\\}", text)',
         'r"\\\\cite(?:\\[[^]]*\\])?\\{([^}]+)\\}", active_text)'),
    ]
    for old, new in edits:
        if text.count(old) != 1:
            raise ValueError(f"Expected exactly one source anchor: {old!r}")
        text = text.replace(old, new, 1)
    tree = ast.parse(text)
    lines = text.splitlines(keepends=True)
    replacements = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Assert):
            if node.end_lineno != node.lineno or node.msg is None:
                raise ValueError("Unexpected assertion shape")
            indent = lines[node.lineno - 1][:node.col_offset]
            test = ast.get_source_segment(text, node.test)
            message = ast.get_source_segment(text, node.msg)
            replacements.append((node.lineno - 1, f"{indent}require({test}, {message})\n"))
    if len(replacements) != 5:
        raise ValueError(f"Expected five assert statements, got {len(replacements)}")
    for index, replacement in replacements:
        lines[index] = replacement
    result = "".join(lines)
    if any(isinstance(node, ast.Assert) for node in ast.walk(ast.parse(result))):
        raise RuntimeError("An assertion survived candidate generation")
    return result

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.destination.resolve():
        parser.error("Source and destination must differ; no in-place writes")
    result = patched_source(args.source.read_text(encoding="utf-8"))
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    with args.destination.open("x", encoding="utf-8", newline="\n") as output:
        output.write(result)

if __name__ == "__main__":
    main()
