"""Build the single-file Wolfram package used by Get[raw-GitHub-URL].

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
LOAD = re.compile(r'^Get\[FileNameJoin\[\{\$kernelDirectory, "([A-Za-z0-9_]+\.wl)"\}\]\];[ \t]*$', re.M)
DIRECTORY = '$kernelDirectory = DirectoryName[$InputFileName];'


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
        code = executable_text(text)
        text = LOAD.sub(lambda match: inline(match[1])
                        if code[match.start():match.start() + 3] == "Get" else match[0], text)
        code = executable_text(text)
        dependency = re.search(r'(?<![\w$])(?:Get|Needs|Import|OpenRead|ReadList|Read|BinaryRead|URLRead|URLExecute|URLDownload)\s*\[|\$(?:InputFileName|Input|kernelDirectory)\b', code)
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
              "   This file is self-contained and can be loaded directly by URL.\n"
              "   SPDX-License-Identifier: MIT *)\n\n")
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
