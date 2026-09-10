"""Dry-run-first focused proposals for AsymptoticAnalysis at 6687962.

Only canonical source files are changed. Wolfram edits have NOT been run in a
native kernel. The builder edit is tested against the retrieved baseline.
New code: MIT-0. No network access and no checksum files are produced.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess
import sys

REVISION = "6687962f3c858a4f93623cfc496f33e35c6763d4"
OLD_LOG_1 = 'Log[u^k_] /; FreeQ[k, u] :> k Log[u]'
NEW_LOG_1 = ('Log[u^k_] /; FreeQ[k, u] && '
             'TrueQ[Simplify[Element[k, Reals], ass]] :> k Log[u]')
OLD_LOG_2 = ('Log[c_ u^k_.] /; FreeQ[c, u] && FreeQ[k, u] && '
             'TrueQ[Simplify[c > 0, ass]] :> Log[c] + k Log[u]')
NEW_LOG_2 = ('Log[c_ u^k_.] /; FreeQ[c, u] && FreeQ[k, u] && '
             'TrueQ[Simplify[c > 0, ass]] && '
             'TrueQ[Simplify[Element[k, Reals], ass]] :> Log[c] + k Log[u]')
OLD_BACKEND = 'backend = If[values === {}, Automatic, ReleaseHold[First[values]]];'
NEW_BACKEND = ('backend = If[values === {},\n'
               '    OptionValue[AsymptoticExpansion, {}, "Backend"],\n'
               '    ReleaseHold[First[values]]];')
OLD_DEPENDENCY = r"(?<![\w$])(?:Get|Needs|Import|OpenRead|ReadList|Read|BinaryRead|URLRead|URLExecute|URLDownload)\s*\[|\$(?:InputFileName|Input|kernelDirectory)\b"
NEW_DEPENDENCY = r"(?<![\w$])(?:(?:Get|Needs|Import|OpenRead|ReadList|Read|BinaryRead|URLRead|URLExecute|URLDownload)|\$(?:InputFileName|Input|kernelDirectory))(?![\w$])"

EDITS = {
    "N01": ("src/Kernel/AsymptoticAnalysis.wl", [(OLD_LOG_1, NEW_LOG_1), (OLD_LOG_2, NEW_LOG_2)]),
    "N02": ("src/Kernel/NativeCompatibility.wl", [(OLD_BACKEND, NEW_BACKEND)]),
    "N03": ("validation/build_standalone.py", [(OLD_DEPENDENCY, NEW_DEPENDENCY)]),
}


def transform(text: str, edits: list[tuple[str, str]]) -> str:
    """Require every exact anchor once; never guess at a changed implementation."""
    for old, new in edits:
        count = text.count(old)
        if count != 1:
            raise ValueError(f"Expected exactly one source anchor, found {count}: {old[:100]}")
        text = text.replace(old, new, 1)
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    parser.add_argument("--only", nargs="+", choices=tuple(EDITS), default=list(EDITS))
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    root = args.repository.resolve()
    try:
        current = subprocess.check_output(
            ["git", "-C", str(root), "rev-parse", "HEAD"], text=True, stderr=subprocess.PIPE
        ).strip()
        if current != REVISION:
            raise ValueError(f"Expected revision {REVISION}; checkout is {current}.")
        plans = []
        for key in dict.fromkeys(args.only):
            rel, edits = EDITS[key]
            path = root / rel
            if not path.is_file():
                raise ValueError(f"Missing canonical source: {path}")
            # Verify against the pinned commit itself, rather than an external digest file.
            pinned = subprocess.check_output(["git", "-C", str(root), "show", f"HEAD:{rel}"])
            old = path.read_text(encoding="utf-8")
            if old != pinned.decode("utf-8").replace("\r\n", "\n"):
                raise ValueError(f"Refusing locally modified source: {rel}")
            new = transform(old, edits)
            backup = path.with_name(path.name + ".before-focused-audit")
            if args.apply and backup.exists():
                raise ValueError(f"Refusing to overwrite backup: {backup}")
            plans.append((key, rel, path, backup, old, new))
        # Preflight all sources and backups before the first write.
        for key, rel, path, backup, old, new in plans:
            print(f"\n# {key}\n", end="")
            sys.stdout.writelines(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                                    fromfile=rel, tofile=rel + " (proposal)"))
        if args.apply:
            for _, _, path, backup, _, new in plans:
                backup.write_bytes(path.read_bytes())
                with path.open("w", encoding="utf-8", newline="\n") as out:
                    out.write(new)
            print("\nCanonical files changed. Test modular sources, then regenerate the standalone.")
            print("Wolfram edits require native validation; this command does not provide it.")
        else:
            print("\nDry run only; no files changed.")
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Patch refused: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
