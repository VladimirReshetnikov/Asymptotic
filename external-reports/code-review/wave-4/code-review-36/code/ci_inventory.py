#!/usr/bin/env python3
"""Fail-closed inventory/CI-partition check for the pinned portable-test layout.

Usage: python ci_inventory.py /path/to/Asymptotic
Reads files only. Does not start a kernel, mutate the repo, or require PyYAML.
The small lexical scanner accepts whitespace and nested WL comments. It is
not a general Wolfram parser: dynamic test registration is explicitly refused.
The workflow reader admits the current literal suite matrix/bash case layout;
a structural workflow refactor requires an explicit update, not silent skipping.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import re
import sys


def tokens(text: str) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    i = 0
    while i < len(text):
        if text[i].isspace():
            i += 1
            continue
        if text.startswith("(*", i):
            depth = 1
            i += 2
            while i < len(text) and depth:
                if text.startswith("(*", i):
                    depth += 1
                    i += 2
                elif text.startswith("*)", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            if depth:
                raise ValueError("Unclosed Wolfram comment")
            continue
        if text[i] == '"':
            i += 1
            buf = []
            while i < len(text) and text[i] != '"':
                if text[i] == "\\":
                    i += 1
                    if i >= len(text):
                        raise ValueError("Unclosed Wolfram string escape")
                    # Preserve escape spellings; IDs with escapes are refused later.
                    buf.append("\\" + text[i])
                    i += 1
                else:
                    buf.append(text[i])
                    i += 1
            if i == len(text):
                raise ValueError("Unclosed Wolfram string")
            out.append(("string", "".join(buf)))
            i += 1
            continue
        m = re.match(r"[A-Za-z$][A-Za-z0-9$`]*", text[i:])
        if m:
            out.append(("name", m.group()))
            i += len(m.group())
        else:
            out.append(("punct", text[i]))
            i += 1
    return out


def discover_cases(text: str) -> list[tuple[str, str]]:
    ts = tokens(text)
    cases: list[tuple[str, str]] = []
    i = 0
    while i < len(ts):
        if ts[i] != ("name", "portableTest") or i + 1 == len(ts) or ts[i + 1][1] != "[":
            i += 1
            continue
        # Locate this call's matching ] without reading strings as syntax.
        depth = 1
        j = i + 2
        while j < len(ts) and depth:
            if ts[j] == ("punct", "["):
                depth += 1
            elif ts[j] == ("punct", "]"):
                depth -= 1
            j += 1
        if depth:
            raise ValueError("Unclosed portableTest call")
        # The suite's portableTest[id_String,...] := definition is not a case.
        if ts[j:j + 2] == [("punct", ":"), ("punct", "=")]:
            i = j + 2
            continue
        args = ts[i + 2:j - 1]
        if (len(args) < 4 or args[0][0] != "string" or args[1] != ("punct", ",")
                or args[2][0] != "string" or args[3] != ("punct", ",")):
            raise ValueError("Only direct literal portableTest IDs/groups are admitted")
        name, group = args[0][1], args[2][1]
        if not re.fullmatch(r"[a-z0-9-]+", name) or not re.fullmatch(r"[a-z][a-z0-9-]*", group):
            raise ValueError(f"Noncanonical test ID/group: {name!r}, {group!r}")
        cases.append((name, group))
        i = j
    if not cases or len({name for name, _ in cases}) != len(cases):
        raise ValueError("Empty inventory or duplicate test IDs")
    return cases


def workflow_shards(text: str) -> dict[str, tuple[str, ...]]:
    matrices = re.findall(r"^\s*suite:\s*\[([a-z,\s-]+)\]\s*$", text, re.MULTILINE)
    if len(matrices) != 1:
        raise ValueError("Expected exactly one literal suite matrix")
    names = [part.strip() for part in matrices[0].split(",")]
    if len(set(names)) != len(names) or not all(names):
        raise ValueError("Duplicate/empty matrix shard")
    entries = re.findall(r"^\s*([a-z-]+)\)\s+groups=\(([a-z\s-]+)\)\s*;;\s*$", text, re.MULTILINE)
    shards = {name: tuple(groups.split()) for name, groups in entries}
    if len(shards) != len(entries) or set(names) != set(shards):
        raise ValueError("Suite matrix and literal bash shard definitions differ")
    if any(len(set(groups)) != len(groups) for groups in shards.values()):
        raise ValueError("Duplicate group inside a shard")
    return shards


def verify_partition(cases: list[tuple[str, str]], shards: dict[str, tuple[str, ...]]) -> dict:
    if not cases or len({name for name, _ in cases}) != len(cases):
        raise ValueError("Empty inventory or duplicate case IDs")
    owners = {name: [shard for shard, groups in shards.items() if group in groups]
              for name, group in cases}
    invalid = {name: owner for name, owner in owners.items() if len(owner) != 1}
    if invalid:
        raise ValueError(f"Every test must have exactly one shard: {invalid}")
    empty = [shard for shard in shards if not any(shard in o for o in owners.values())]
    if empty:
        raise ValueError(f"Empty shards: {empty}")
    return {"cases": len(cases), "shards": len(shards), "exactly_once_per_entry": True}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    args = parser.parse_args()
    try:
        suite = (args.repository / "validation/MathicsTests.wl").read_text(encoding="utf-8")
        workflow = (args.repository / ".github/workflows/mathics.yml").read_text(encoding="utf-8")
        print(verify_partition(discover_cases(suite), workflow_shards(workflow)))
    except (OSError, ValueError) as error:
        print(f"Inventory check failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
