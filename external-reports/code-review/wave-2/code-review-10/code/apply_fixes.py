#!/usr/bin/env python3
"""Preview/apply two narrow edits to a CLEAN, pinned Git checkout.

No network access; no edits to the generated standalone. Run the upstream
builder after applying. Native spot checks are not a full release test.
"""
from __future__ import annotations
import argparse
import difflib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from typing import Any

SPEC_PATH = Path(__file__).with_name("patch_spec.json")


def transform(text: str, edits: list[dict[str, str]]) -> str:
    """Require every source anchor exactly once; reject drift/reapplication."""
    result = text
    for edit in edits:
        before = edit["before"]
        count = result.count(before)
        if count != 1:
            raise ValueError(f"Expected one anchor, found {count}: {before[:100]!r}")
        result = result.replace(before, edit["after"], 1)
    return result


def git(repo: Path, *args: str) -> str:
    p = subprocess.run(["git", "-C", str(repo), *args], text=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if p.returncode:
        raise RuntimeError(p.stderr.strip() or f"git exited {p.returncode}")
    return p.stdout.strip()


def atomic_write(path: Path, data: bytes) -> None:
    fd, name = tempfile.mkstemp(prefix=path.name + ".audit-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="Local Git checkout at the audited commit")
    parser.add_argument("--apply", action="store_true", help="Write canonical files (default: diff only)")
    args = parser.parse_args()
    spec: dict[str, Any] = json.loads(SPEC_PATH.read_text(encoding="utf-8"))
    repo = args.repo.resolve(strict=True)
    if git(repo, "rev-parse", "HEAD") != spec["snapshot"]:
        raise ValueError("HEAD does not match the audited snapshot; rebase/review these edits manually.")
    paths = [p["path"] for p in spec["patches"]]
    if git(repo, "status", "--porcelain", "--", *paths):
        raise ValueError("A target source is modified or staged; refusing to overwrite it.")
    planned: list[tuple[Path, bytes, bytes, Path]] = []
    for patch in spec["patches"]:
        path = repo / patch["path"]
        original = path.read_bytes()
        text = original.decode("utf-8").replace("\r\n", "\n")
        updated = transform(text, patch["edits"])
        backup = path.with_suffix(path.suffix + ".pre-delta-audit")
        if args.apply and backup.exists():
            raise FileExistsError(f"Backup already exists: {backup}")
        sys.stdout.writelines(difflib.unified_diff(
            text.splitlines(keepends=True), updated.splitlines(keepends=True),
            fromfile="a/" + patch["path"], tofile="b/" + patch["path"]))
        planned.append((path, original, updated.encode("utf-8"), backup))
    if args.apply:
        written: list[tuple[Path, bytes]] = []
        backups: list[Path] = []
        try:
            for path, original, updated, backup in planned:
                with backup.open("xb") as f:
                    f.write(original)
                backups.append(backup)
                # Record before the replacement so rollback also covers a partial failure.
                written.append((path, original))
                atomic_write(path, updated)
        except Exception:
            for path, original in reversed(written):
                atomic_write(path, original)
            for backup in backups:
                backup.unlink(missing_ok=True)
            raise
        print("\nCanonical sources updated. Rebuild and test from the repository root:")
        print("  python validation/build_standalone.py")
        print("Then run the audit probes and the upstream native suite in fresh kernels.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, KeyError) as exc:
        print(f"REFUSED: {exc}", file=sys.stderr)
        raise SystemExit(2)
