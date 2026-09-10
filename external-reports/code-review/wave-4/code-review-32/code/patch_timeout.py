"""Generate a narrowly scoped timeout-validation patch; write only with --apply.

The replacement is validated against exact source fragments. The review did not
apply this to the repository. A clean diff is printed by default.
"""
from __future__ import annotations
import argparse
import difflib
from pathlib import Path

OLD_IMPORT = 'import json\nimport os\n'
NEW_IMPORT = 'import json\nimport math\nimport os\n'
OLD_GUARD = '    if args.timeout <= 0:\n        parser.error("--timeout must be positive")\n'
NEW_GUARD = '    if not math.isfinite(args.timeout) or args.timeout <= 0:\n        parser.error("--timeout must be positive and finite")\n'


def patched_text(source: str) -> str:
    if NEW_IMPORT in source and NEW_GUARD in source and OLD_GUARD not in source:
        return source
    if source.count(OLD_IMPORT) != 1 or source.count(OLD_GUARD) != 1:
        raise ValueError('Source differs from the expected runner; no patch was applied')
    if 'import math\n' in source:
        raise ValueError('Unexpected existing math import; review the change manually')
    return source.replace(OLD_IMPORT, NEW_IMPORT, 1).replace(OLD_GUARD, NEW_GUARD, 1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path, help='validation/run_mathics_tests.py')
    parser.add_argument('--apply', action='store_true', help='Explicitly write the validated change')
    args = parser.parse_args()
    old = args.source.read_text(encoding='utf-8')
    try:
        new = patched_text(old)
    except ValueError as error:
        parser.error(str(error))
    print(''.join(difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True),
                                     fromfile=str(args.source), tofile=str(args.source))), end='')
    if args.apply and new != old:
        args.source.write_text(new, encoding='utf-8')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
