"""Regenerate the proposed focused runner patch from the pinned fixture.

This edits only files inside this audit bundle, never a user's repository.
"""
from pathlib import Path
import difflib

BASE = Path(__file__).resolve().parents[1]
p = BASE / 'fixtures' / 'run_mathics_tests.py'
s = p.read_text(encoding='utf-8')

def replace_once(old: str, new: str) -> None:
    global s
    if s.count(old) != 1:
        raise RuntimeError(f'Expected one patch anchor, found {s.count(old)}: {old[:80]}')
    s = s.replace(old, new, 1)

replace_once('import json\n', 'import json\nimport math\n')
replace_once('def fingerprints(source: Path) -> dict[str, str]:\n',
'''def fingerprints(source: Path, dependency_roots: tuple[Path, ...] = ()) -> dict[str, str]:
''')
replace_once('if source.name == "AsymptoticAnalysis.wl" and source.parent.name == "Kernel":',
'''if source.name in {"AsymptoticAnalysis.wl", "init.m"} and source.parent.name == "Kernel":''')
replace_once('        files.update(source.parent.glob("*.wl"))\n',
'''        files.update(source.parent.glob("*.wl"))
        files.update(source.parent.glob("*.m"))
    for root in dependency_roots:
        files.update(path for path in root.rglob("*")
                     if path.is_file() and path.suffix in {".wl", ".m"})
''')
replace_once('        except BaseException:\n',
'''        except KeyboardInterrupt:
            stop_process_tree(process)
            captured, _ = process.communicate(timeout=10)
            output = as_text(captured)
            result = {"Outcome": "Interrupted", "ExitCode": process.returncode}
        except BaseException:
''')
replace_once('    parser.add_argument("--case", action="append", default=[],',
'''    parser.add_argument("--dependency-root", action="append", type=Path, default=[],
                        help="Additional source trees for a custom loader; repeat as needed")
    parser.add_argument("--case", action="append", default=[],''')
replace_once('    if args.timeout <= 0:\n        parser.error("--timeout must be positive")',
'''    if not math.isfinite(args.timeout) or not 0 < args.timeout <= 86400:
        parser.error("--timeout must be finite and positive, and at most 86400 seconds")''')
replace_once('    before = fingerprints(source)\n',
'''    dependency_roots = tuple(root.resolve() for root in args.dependency_root)
    if any(not root.is_dir() for root in dependency_roots):
        parser.error("Each --dependency-root must be an existing directory")
    before = fingerprints(source, dependency_roots)
    coverage = ("ExplicitDependencyRoots" if dependency_roots else
                "CanonicalModular" if source.parent.name == "Kernel" and
                source.name in {"AsymptoticAnalysis.wl", "init.m"} else
                "EntryFileOnly")
''')
replace_once('    results = []\n', '    results = []\n    active_test = None\n')
replace_once('        after = fingerprints(source)\n', '        after = fingerprints(source, dependency_roots)\n')
replace_once('            "TestedSourcesSHA256": before, "Results": results,\n',
'''            "TestedSourcesSHA256": before, "Results": results,
            "DependencyCoverage": coverage,
            "DependencyRoots": [str(root) for root in dependency_roots],
            "Started": len(results) + int(active_test is not None),
            "Completed": len(results),
            "NotStarted": len(cases) - len(results) - int(active_test is not None),
            "ActiveTest": active_test,
''')
replace_once('            print(f"Running {test_id} ...", flush=True)\n',
'''            active_test = {"TestID": test_id, "Group": group,
                           "StartedUTC": datetime.now(timezone.utc).isoformat(),
                           "State": "StartedWithoutResult"}
            write_report(False)
            print(f"Running {test_id} ...", flush=True)
''')
replace_once('            results.append(result)\n', '            results.append(result)\n            active_test = None\n')
replace_once('            if result["Outcome"] == "LaunchError":',
             '            if result["Outcome"] in {"LaunchError", "Interrupted"}:')
replace_once('    report = write_report(True)\n',
'''    report = write_report(len(results) == len(cases) and
                          not any(r["Outcome"] == "Interrupted" for r in results))
''')
# NotRun historically meant "no completed record". Preserve it for compatibility,
# but add explicit Started, Completed, ActiveTest and NotStarted, not a silent rename.
new = BASE / 'patches' / 'run_mathics_tests_candidate.py'
new.write_text(s, encoding='utf-8')
diff = difflib.unified_diff(p.read_text(encoding='utf-8').splitlines(True), s.splitlines(True),
                           fromfile='a/validation/run_mathics_tests.py',
                           tofile='b/validation/run_mathics_tests.py')
(BASE / 'patches' / 'portable_runner.diff').write_text(''.join(diff), encoding='utf-8')
print(new)
