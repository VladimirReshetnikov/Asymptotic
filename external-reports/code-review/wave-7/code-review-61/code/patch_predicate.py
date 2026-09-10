#!/usr/bin/env python3
"""Stage the narrow N01 guard; never modify the input checkout.

The staged modular file still needs its companion modules. Apply the emitted
unified diff in a disposable checkout, then rebuild the root standalone with
the repository's validation/build_standalone.py. This is not a release gate.
Python 3.10+, standard library; git required for repository identity checks.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path
import subprocess

COMMIT = "efa1aeec4845a9c35e140963a0333d0c9ec33b05"
RELATIVE_PATH = "src/Kernel/InverseFunctionExpressions.wl"
OLD = 'Return[And @@ (TrueQ[FullSimplify[Element[#[[2]], Reals], seriesAss[d] && Element[d["LogVariable"], Reals]]] & /@ j[[1]]), Module]];'
NEW = 'Return[j[[2]] === Infinity && And @@ (TrueQ[FullSimplify[Element[#[[2]], Reals], seriesAss[d] && Element[d["LogVariable"], Reals]]] & /@ j[[1]]), Module]];'


def transform(source: str) -> str:
    """Require exactly one unchanged anchor; refuse drift or reapplication."""
    if NEW in source:
        raise ValueError("The N01 guard is already present; refusing reapplication.")
    count = source.count(OLD)
    if count != 1:
        raise ValueError(f"Expected one original Element predicate anchor, found {count}.")
    return source.replace(OLD, NEW, 1)


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(repo), *args], check=True,
                            text=True, encoding="utf-8", capture_output=True,
                            timeout=30)
    return result.stdout


def stage(repository: Path, output: Path) -> Path:
    repo = repository.resolve(strict=True)
    out = output.resolve()
    if not repo.is_dir():
        raise ValueError("Repository must be a directory.")
    if out == repo or repo in out.parents:
        raise ValueError("Output must be outside the input checkout.")
    if out.exists():
        raise FileExistsError(f"Output already exists: {out}")
    if git(repo, "rev-parse", "HEAD").strip() != COMMIT:
        raise ValueError(f"This staging tool requires the pinned commit {COMMIT}.")
    original = git(repo, "show", f"{COMMIT}:{RELATIVE_PATH}")
    working_path = repo / RELATIVE_PATH
    if working_path.is_symlink():
        raise ValueError("Refusing a symlink for the canonical source file.")
    # Universal-newline reading deliberately accepts a CRLF worktree.
    working = working_path.read_text(encoding="utf-8")
    if working != original:
        raise ValueError("The relevant modular source differs from the pinned commit.")
    modified = transform(working)
    patch = "".join(difflib.unified_diff(
        working.splitlines(keepends=True), modified.splitlines(keepends=True),
        fromfile="a/" + RELATIVE_PATH, tofile="b/" + RELATIVE_PATH))
    out.mkdir(parents=True, exist_ok=False)
    target = out / RELATIVE_PATH
    target.parent.mkdir(parents=True)
    target.write_text(modified, encoding="utf-8", newline="\n")
    patch_path = out / "predicate-realness.patch"
    patch_path.write_text(patch, encoding="utf-8", newline="\n")
    (out / "README.txt").write_text(
        "N01: exact-jet-only proof in the Element[..., Reals] branch.\n"
        "This is a conservative candidate, not a complete real-germ prover.\n"
        "A focused Wolfram 15 witness and exact-polynomial control were checked.\n"
        "Mathics and the complete upstream suite were not run by this audit.\n"
        "Apply predicate-realness.patch and rebuild the standalone from modules.\n",
        encoding="utf-8")
    return patch_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        print(stage(args.repository, args.output))
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        parser.exit(2, f"Patch staging failed: {exc}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
