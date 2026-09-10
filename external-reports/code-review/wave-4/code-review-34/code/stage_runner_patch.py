"""Stage a small, strict-context repair of the pinned portable runner.

Does not edit the source in place. This is checkpoint validation, not an
adversarial sandbox and not proof of absence of between-checkpoint ABA edits.
"""
from __future__ import annotations
import argparse
from pathlib import Path


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError("Expected exactly one matching source context; refusing this revision")
    return text.replace(old, new, 1)


def patched_text(text: str) -> str:
    text = replace_once(text, "import json\n", "import json\nimport math\n")
    text = replace_once(text,
        '    if args.timeout <= 0:\n        parser.error("--timeout must be positive")',
        '    if not math.isfinite(args.timeout) or not 0 < args.timeout <= 86400:\n'
        '        parser.error("--timeout must be finite and in (0, 86400] seconds")')
    text = replace_once(text, '    results = []\n',
        '    results = []\n    sources_unchanged = True\n    snapshot_matched = True\n')
    text = replace_once(text, '    def write_report(complete: bool) -> dict:\n        after = fingerprints(source)',
        '    def write_report(complete: bool) -> dict:\n        nonlocal sources_unchanged\n'
        '        after = fingerprints(source)\n'
        '        sources_unchanged = sources_unchanged and before == after')
    text = replace_once(text, '"NotRun": len(cases) - len(results), "SourcesUnchangedDuringRun": before == after,',
        '"NotRun": len(cases) - len(results), "SourcesUnchangedDuringRun": sources_unchanged,\n'
        '            "SnapshotMatchedAtCheckpoints": snapshot_matched,')
    text = replace_once(text, '        for test_id, group in cases:\n            print(',
        '        for test_id, group in cases:\n'
        '            if not frozen_suite.is_file() or frozen_suite.read_bytes() != suite_snapshot:\n'
        '                snapshot_matched = False\n                break\n            print(')
    text = replace_once(text, '            results.append(result)\n            write_report(False)',
        '            results.append(result)\n'
        '            snapshot_matched = snapshot_matched and frozen_suite.is_file() and frozen_suite.read_bytes() == suite_snapshot\n'
        '            write_report(False)\n'
        '            if not snapshot_matched:\n                break')
    text = replace_once(text, '    report = write_report(True)',
        '    report = write_report(len(results) == len(cases))')
    text = replace_once(text,
        '    return 0 if succeeded == len(cases) and report["SourcesUnchangedDuringRun"] else 1',
        '    return 0 if succeeded == len(cases) and report["SourcesUnchangedDuringRun"] and snapshot_matched else 1')
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    if args.source.resolve() == args.destination.resolve():
        parser.error("Choose a distinct destination; staging never edits in place")
    result = patched_text(args.source.read_text(encoding="utf-8"))
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    args.destination.write_text(result, encoding="utf-8")


if __name__ == "__main__":
    main()
