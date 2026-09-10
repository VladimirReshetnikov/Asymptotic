"""Stage a narrow patch; never edit the checkout in place.

Usage:
  python code/apply_runner_patch.py /path/to/Asymptotic --output /tmp/patched-runner.py

The output is a candidate copy plus a unified diff. Source-shape checks fail
closed if the inspected implementation has changed. No hashes are generated.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

CHANGES = (
    ("import json\n", "import json\nimport math\n"),
    ('executable = str(Path(args.wolfram).resolve()) if Path(args.wolfram).is_file() else args.wolfram',
     'executable = os.path.abspath(args.wolfram) if Path(args.wolfram).is_file() else args.wolfram'),
    ('executable = str(Path(executable).resolve())',
     'executable = os.path.abspath(executable)'),
    ('if args.timeout <= 0:\n        parser.error("--timeout must be positive")',
     'if not math.isfinite(args.timeout) or not (0 < args.timeout <= 86400):\n        parser.error("--timeout must be finite and in (0, 86400] seconds")'),
)

def transform(text: str) -> str:
    for before, after in CHANGES:
        if text.count(before) != 1:
            raise ValueError(f"Expected exactly one source fragment: {before!r}")
        text = text.replace(before, after, 1)
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    source = args.repository / "validation/run_mathics_tests.py"
    if not source.is_file():
        parser.error(f"not a repository runner: {source}")
    if args.output.resolve() == source.resolve():
        parser.error("choose a separate staging output; in-place modification is disabled")
    original = source.read_text(encoding="utf-8")
    try:
        revised = transform(original)
    except ValueError as exc:
        parser.error(str(exc))
    compile(revised, str(args.output), "exec")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(revised, encoding="utf-8")
    patch = ''.join(difflib.unified_diff(original.splitlines(True), revised.splitlines(True),
        fromfile="a/validation/run_mathics_tests.py", tofile="b/validation/run_mathics_tests.py"))
    patch_path = args.output.with_suffix(args.output.suffix + ".patch")
    patch_path.write_text(patch, encoding="utf-8")
    print(args.output)
    print(patch_path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
