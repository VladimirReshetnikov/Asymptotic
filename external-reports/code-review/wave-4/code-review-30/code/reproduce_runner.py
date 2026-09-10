#!/usr/bin/env python3
"""Exercise the actual pinned portable runner with a protocol-only fake kernel.

No Wolfram Language or Mathics code is evaluated. This tests the runner's
source-integrity acceptance rule, not the mathematics package. Temporary
hash-bearing runner reports are discarded; the retained evidence contains
observations and process output, not checksum files.
"""
from __future__ import annotations
import argparse
import difflib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

BUNDLE = Path(__file__).resolve().parents[1]
UPSTREAM = BUNDLE / 'upstream-excerpts/run_mathics_tests.py'


def sticky_patch(text: str) -> str:
    needle = '    results = []\n\n    def write_report(complete: bool) -> dict:\n        after = fingerprints(source)'
    replacement = ('    results = []\n    sources_unchanged = True\n\n'
                   '    def write_report(complete: bool) -> dict:\n'
                   '        nonlocal sources_unchanged\n'
                   '        after = fingerprints(source)\n'
                   '        sources_unchanged = sources_unchanged and before == after')
    if text.count(needle) != 1:
        raise ValueError('Pinned runner context does not match; do not patch another version blindly.')
    text = text.replace(needle, replacement)
    needle = '"SourcesUnchangedDuringRun": before == after'
    if text.count(needle) != 1:
        raise ValueError('Unexpected report layout')
    return text.replace(needle, '"SourcesUnchangedDuringRun": sources_unchanged')


def experiment(mode: str, patched: bool) -> dict:
    """Modes: observed-change/restore, or an unwatched relocated sibling."""
    with tempfile.TemporaryDirectory(prefix='asymptotic-runner-audit-') as td:
        root = Path(td)
        validation = root / 'validation'
        validation.mkdir()
        runner = validation / 'run_mathics_tests.py'
        source_text = UPSTREAM.read_text(encoding='utf-8')
        runner.write_text(sticky_patch(source_text) if patched else source_text, encoding='utf-8')
        directory = root / ('Kernel' if mode in {'restore','control','permanent'} else 'RelocatedModules')
        directory.mkdir()
        source = directory / 'AsymptoticAnalysis.wl'
        source.write_text('Get[FileNameJoin[{DirectoryName[$InputFileName], "Helper.wl"}]];\n', encoding='utf-8')
        helper = directory / 'Helper.wl'
        helper.write_text('original = 1;\n', encoding='utf-8')
        victim = source if mode in {'restore','control','permanent'} else helper
        original = victim.read_text(encoding='utf-8')
        ids = (['change-source', 'restore-source'] if mode == 'restore' else
               ['no-change'] if mode == 'control' else
               ['change-source'] if mode == 'permanent' else ['change-sibling'])
        (validation / 'MathicsTests.wl').write_text(''.join(
            f'portableTest["{id}", "integrity", 2, 2];\n' for id in ids), encoding='utf-8')
        report = root / 'report.json'
        observer = root / 'observer.json'
        fake = root / 'fake_kernel.py'
        fake.write_text(f'#!{sys.executable}\n' + r'''
# Protocol-only test double: NOT a Wolfram or Mathics evaluator.
import json, os
from pathlib import Path
case = os.environ['ASYMPTOTIC_PORTABLE_CASE']
victim = Path(os.environ['AUDIT_VICTIM'])
if case == 'restore-source':
    previous = json.loads(Path(os.environ['AUDIT_REPORT']).read_text())
    Path(os.environ['AUDIT_OBSERVER']).write_text(json.dumps({
        'intermediate_unchanged_flag': previous['SourcesUnchangedDuringRun']}))
    victim.write_text(os.environ['AUDIT_ORIGINAL'])
elif case != 'no-change':
    victim.write_text(os.environ['AUDIT_ORIGINAL'] + '(* deliberate audit mutation *)\n')
print('ASYMPTOTIC_PORTABLE_KERNEL\tPROTOCOL-ONLY-FAKE-KERNEL')
print('ASYMPTOTIC_PORTABLE_ITERATION_LIMIT\t1000000')
print('ASYMPTOTIC_PORTABLE_ACTUAL_BEGIN\n2\nASYMPTOTIC_PORTABLE_ACTUAL_END')
print('ASYMPTOTIC_PORTABLE_EXPECTED_BEGIN\n2\nASYMPTOTIC_PORTABLE_EXPECTED_END')
print('ASYMPTOTIC_PORTABLE_RESULT\t' + case + '\tSuccess')
''', encoding='utf-8')
        fake.chmod(0o755)
        env = dict(os.environ, AUDIT_VICTIM=str(victim), AUDIT_REPORT=str(report),
                   AUDIT_OBSERVER=str(observer), AUDIT_ORIGINAL=original)
        completed = subprocess.run([sys.executable, str(runner), '--wolfram', str(fake),
                                    '--source', str(source), '--output', str(report),
                                    '--timeout', '10'], env=env, capture_output=True, text=True, timeout=40)
        data = json.loads(report.read_text(encoding='utf-8'))
        observed = json.loads(observer.read_text()) if observer.exists() else {}
        watched = list(data['TestedSourcesSHA256'])
        return dict(mode=mode, sticky_patch=patched, runner_exit=completed.returncode,
                    selected=data['Selected'], succeeded=data['Succeeded'],
                    final_unchanged_flag=data['SourcesUnchangedDuringRun'],
                    source_still_changed=victim.read_text(encoding='utf-8') != original,
                    helper_watched=any(p.endswith('/Helper.wl') for p in watched),
                    observed=observed,
                    stdout=completed.stdout.replace(str(root), '<TEMP>'),
                    scope='Actual pinned Python runner; protocol-only fake kernel. No WL package execution.')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=BUNDLE/'evidence/runner_experiments.json')
    args = parser.parse_args()
    if os.name == 'nt':
        raise SystemExit('This POSIX executable test-double fixture needs WSL/Linux/macOS; the runner itself is cross-platform.')
    result = [experiment('restore', False), experiment('restore', True), experiment('relocated', False),
              experiment('control',False), experiment('control',True),
              experiment('permanent',False), experiment('permanent',True)]
    assert result[0]['observed']['intermediate_unchanged_flag'] is False
    assert result[0]['runner_exit'] == 0 and result[0]['final_unchanged_flag'] is True
    assert result[1]['runner_exit'] == 1 and result[1]['final_unchanged_flag'] is False
    assert result[2]['source_still_changed'] and not result[2]['helper_watched']
    assert result[2]['runner_exit'] == 0 and result[2]['final_unchanged_flag'] is True
    assert all(r['runner_exit'] == 0 and r['final_unchanged_flag'] for r in result[3:5])
    assert all(r['runner_exit'] == 1 and not r['final_unchanged_flag'] for r in result[5:7])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    upstream = UPSTREAM.read_text(encoding='utf-8')
    patch = ''.join(difflib.unified_diff(upstream.splitlines(keepends=True),
                    sticky_patch(upstream).splitlines(keepends=True),
                    fromfile='a/validation/run_mathics_tests.py', tofile='b/validation/run_mathics_tests.py'))
    (BUNDLE/'code/runner_sticky_flag.patch').write_text(patch, encoding='utf-8')
    print(json.dumps(result, indent=2))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
