"""Build the single-file Wolfram package used by Get[URLDownload[url]].

The canonical implementation remains in src/Kernel. Companion
loads are expanded in place, preserving Wolfram's streaming context changes.
Run with --check to verify freshness without writing any files.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
KERNEL = ROOT / "src" / "Kernel"
TARGET = ROOT / "AsymptoticAnalysis.wl"
LOAD = re.compile(r'^loadModule\["([A-Za-z0-9_]+\.wl)"\];[ \t]*$', re.M)
MATHICS_LOAD = re.compile(r'^If\[StringContainsQ\[\$Version, "Mathics"\], loadModule\["([A-Za-z0-9_]+\.wl)"\]\];[ \t]*$', re.M)
DIRECTORY = '$kernelDirectory = DirectoryName[$InputFileName];'
# The guarded module loader (W4-17) reads companion files; the standalone
# inlines every companion, so the block is replaced by a comment.
LOADER = re.compile(r'^\(\* BEGIN MODULAR LOADER \*\)\n.*?^\(\* END MODULAR LOADER \*\)\n', re.M | re.S)
LOADER_REPLACEMENT = "(* Standalone: the guarded modular loader is not needed; every companion is inlined below. *)\n"


def executable_text(text: str) -> str:
    """Mask strings and nested comments before checking dependency tokens."""
    result = list(text)
    i, depth, quoted = 0, 0, False
    while i < len(text):
        if depth:
            if text.startswith("(*", i):
                result[i:i + 2] = "  "
                depth += 1
                i += 2
            elif text.startswith("*)", i):
                result[i:i + 2] = "  "
                depth -= 1
                i += 2
            else:
                result[i] = "\n" if text[i] == "\n" else " "
                i += 1
        elif quoted:
            result[i] = "\n" if text[i] == "\n" else " "
            if text[i] == "\\":
                if i + 1 >= len(text):
                    raise ValueError("Unterminated string escape")
                result[i + 1] = " "
                i += 2
            else:
                if text[i] == '"':
                    quoted = False
                i += 1
        elif text.startswith("(*", i):
            result[i:i + 2] = "  "
            depth = 1
            i += 2
        elif text[i] == '"':
            result[i] = " "
            quoted = True
            i += 1
        else:
            i += 1
    if depth or quoted:
        raise ValueError("Unterminated Wolfram comment or string")
    return "".join(result)


def mathics_bootstrap(source: str) -> str:
    """Delay parsing adapters as well as their evaluation on the Wolfram kernel.

    Scan separately parses each top-level statement, preserving streaming
    Begin/End and symbol resolution just as Get does. Splitting the masked
    source ignores semicolons in strings, comments, and nested expressions.
    """
    code = executable_text(source)
    # Association delimiters group like brackets: a semicolon inside
    # <| ... |>, in ASCII, long-name or private-use spelling, does not end a
    # statement (wave-7 report 59 N02). A delimiter stack also rejects a
    # mismatched closer, which a depth counter accepted.
    opening = {"(": ")", "[": "]", "{": "}", "<|": "|>",
               r"\[LeftAssociation]": "|>", "": "|>"}
    closing = {")": ")", "]": "]", "}": "}", "|>": "|>",
               r"\[RightAssociation]": "|>", "": "|>"}
    tokens = sorted(set(opening) | set(closing), key=len, reverse=True)
    statements, start, stack = [], 0, []
    i = 0
    while i < len(code):
        # Condition (/;) and Span (;;) contain semicolons but do not end a
        # statement. Consume the complete operator before considering a
        # CompoundExpression terminator, including a trailing span (;;;).
        if code[i:i + 2] in {"/;", ";;"}:
            i += 2
            continue
        token = next((t for t in tokens if code.startswith(t, i)), None)
        if token is not None:
            if token in opening:
                stack.append(opening[token])
            elif not stack or stack[-1] != closing[token]:
                raise ValueError("Unbalanced Mathics bootstrap source")
            else:
                stack.pop()
            i += len(token)
            continue
        if code[i] == ";" and not stack:
            statements.append(source[start:i + 1])
            start = i + 1
        i += 1
    if stack:
        raise ValueError("Unbalanced Mathics bootstrap source")
    if code[start:].strip():
        statements.append(source[start:])
    quoted = ",\n".join(json.dumps(s, ensure_ascii=False) for s in statements)
    return ('If[StringContainsQ[$Version, "Mathics"], Scan[ToExpression, {\n'
            + quoted + '\n}]];')


def assemble() -> tuple[bytes, list[str]]:
    sources: list[str] = []

    def inline(name: str) -> str:
        path = (KERNEL / name).resolve()
        if path.parent != KERNEL.resolve() or path.suffix != ".wl":
            raise ValueError(f"Dependency is outside the kernel directory: {name}")
        if name in sources:
            raise ValueError(f"Repeated or cyclic dependency: {name}")
        text = path.read_text(encoding="utf-8")
        sources.append(name)
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        if name == "AsymptoticAnalysis.wl":
            if text.count(DIRECTORY) != 1:
                raise ValueError("Review the changed modular entry-point directory setup")
            text = text.replace(DIRECTORY, "(* Standalone: every companion is included below. *)")
            if len(LOADER.findall(text)) != 1:
                raise ValueError("Review the changed modular loader block")
            text = LOADER.sub(LOADER_REPLACEMENT, text)
        code = executable_text(text)
        text = MATHICS_LOAD.sub(lambda match: mathics_bootstrap(inline(match[1]))
                               if code[match.start():match.start() + 2] == "If" else match[0], text)
        code = executable_text(text)
        text = LOAD.sub(lambda match: inline(match[1])
                        if code[match.start():match.start() + 10] == "loadModule" else match[0], text)
        code = executable_text(text)
        # A conservative token gate: any spelling of a loading or file
        # primitive - bracket call, prefix or postfix application, Apply, Map,
        # a qualified System` name, or the bare symbol passed as an argument -
        # is an unresolved dependency (W3-11). Strings and comments are masked.
        dependency = re.search(r'(?<![\w$`])(?:System`)?(?:Get|Needs|Import|OpenRead|ReadList|Read|BinaryRead|URLRead|URLExecute|URLDownload|loadModule)(?![\w$`])|\$(?:InputFileName|Input|kernelDirectory)\b', code)
        if dependency:
            raise ValueError(f"Unresolved load or file-dependent code in {name}: {dependency[0]}")
        return (f"(* BEGIN SOURCE: src/Kernel/{name}\n"
                f"   Source SHA256 (UTF-8/LF): {digest} *)\n" + text.rstrip() +
                f"\n(* END SOURCE: src/Kernel/{name} *)\n")

    body = inline("AsymptoticAnalysis.wl")
    header = ("(* ::Package:: *)\n"
              "(* GENERATED FILE. Edit src/Kernel/*.wl instead.\n"
              "   Rebuild: python validation/build_standalone.py\n"
              "   Verify:  python validation/build_standalone.py --check\n"
              "   This file is self-contained; load a remote URL with Get[URLDownload[url]].\n"
              "   SPDX-License-Identifier: MIT-0 *)\n\n")
    return (header + body).encode("utf-8"), sources


def build(check: bool = False) -> dict:
    data, sources = assemble()
    if check:
        if not TARGET.exists() or TARGET.read_bytes() != data:
            raise SystemExit("AsymptoticAnalysis.wl is stale; run python validation/build_standalone.py")
    else:
        # Assemble and validate everything before replacing the artifact.
        temporary = TARGET.with_suffix(".wl.tmp")
        temporary.write_bytes(data)
        temporary.replace(TARGET)
    result = {"Artifact": TARGET.name, "SourceFiles": len(sources),
              "Bytes": len(data), "SHA256": hashlib.sha256(data).hexdigest(),
              "MatchesSources": True}
    print(json.dumps(result))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
