"""Compare package definitions in fresh official Wolfram kernels.

Example (baseline and candidate are repository roots or extracted git archives):
  python validation/check_mathics_definitions.py --baseline OLD --candidate . \
    --wolfram wolfram.exe --output native-definitions.json --captures captures

The default checks both modular and standalone entry points. Package inputs and
the Wolfram capture script are copied to temporary snapshots before execution;
hash checks reject changes to either the originals or the snapshots. Each load is followed by a
reload and checks that selected System builtins remain unchanged. This is a
definition and observed-behavior comparison, not an exhaustive behavior proof.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CAPTURE = Path(__file__).with_name("CheckMathicsDefinitions.wl")
ENTRIES = {"modular": Path("src/Kernel/AsymptoticAnalysis.wl"),
           "standalone": Path("AsymptoticAnalysis.wl")}


def fingerprint(paths: dict[str, Path]) -> dict[str, str]:
    return {name: hashlib.sha256(path.read_bytes()).hexdigest()
            for name, path in sorted(paths.items())}


def fingerprints_match(paths: dict[str, Path], expected: dict[str, str]) -> bool:
    try:
        return fingerprint(paths) == expected
    except OSError:
        return False


def inputs(root: Path, forms: list[str]) -> dict[str, Path]:
    paths = {str(ENTRIES[form]).replace("\\", "/"): root / ENTRIES[form] for form in forms}
    if "modular" in forms:
        paths.update({path.relative_to(root).as_posix(): path
                      for path in (root / "src/Kernel").iterdir()
                      if path.is_file() and path.suffix in {".wl", ".m"}})
    if any(not path.is_file() for path in paths.values()):
        raise ValueError("A requested package entry file is missing")
    return paths


def normalized(data: dict) -> dict:
    """Normalize only the InputForm spelling of the source directory."""
    result = json.loads(json.dumps(data))
    directory = str(Path(data["PackagePath"]).parent).replace("\\", "\\\\")
    for phase in ("AfterLoad", "AfterReload"):
        for definition in result[phase]["Definitions"].values():
            for field, text in definition.items():
                definition[field] = text.replace(directory, "<PACKAGE_SOURCE_DIRECTORY>")
    return result


def compare(before: dict, after: dict) -> dict:
    before, after = normalized(before), normalized(after)
    bdefs = before["AfterLoad"]["Definitions"]
    adefs = after["AfterLoad"]["Definitions"]
    added, removed = sorted(adefs.keys() - bdefs.keys()), sorted(bdefs.keys() - adefs.keys())
    changed = {name: {field: {"Baseline": bdefs[name][field], "Candidate": adefs[name][field]}
                      for field in bdefs[name] if bdefs[name][field] != adefs[name][field]}
               for name in sorted(bdefs.keys() & adefs.keys()) if bdefs[name] != adefs[name]}
    metadata = ["Kernel", "SystemID", "ContextBefore", "ContextAfterLoad", "ContextAfterReload",
                "ContextPathBefore", "ContextPathAfterLoad", "ContextPathAfterReload",
                "BuiltinsBefore", "BuiltinsAfterLoad", "BuiltinsAfterReload",
                "BehaviorBefore", "BehaviorAfterLoad", "BehaviorAfterReload"]
    differences = {field: {"Baseline": before[field], "Candidate": after[field]}
                   for field in metadata if before[field] != after[field]}
    for phase in ("AfterLoad", "AfterReload"):
        if before[phase]["Contexts"] != after[phase]["Contexts"]:
            differences[phase + "Contexts"] = {"Baseline": before[phase]["Contexts"],
                                               "Candidate": after[phase]["Contexts"]}
    # Native startup lazily loads unrelated packages (for example CURLLink).
    # Retain that diagnostic separately; original-versus-original runs can differ.
    ambient = {field: {"Added": sorted(set(after[field]) - set(before[field])),
                       "Removed": sorted(set(before[field]) - set(after[field]))}
               for field in ("AmbientPackagesBefore", "AmbientPackagesAfterLoad", "AmbientPackagesAfterReload")
               if before[field] != after[field]}
    passed = before["Passed"] and after["Passed"] and not (added or removed or changed or differences)
    return {"Passed": passed, "BaselineSymbols": len(bdefs), "CandidateSymbols": len(adefs),
            "AddedSymbols": added, "RemovedSymbols": removed, "ChangedSymbols": changed,
            "MetadataDifferences": differences, "AmbientStartupPackageDifferences": ambient,
            "BaselineLoadReloadAndBuiltinChecksPassed": before["Passed"],
            "CandidateLoadReloadAndBuiltinChecksPassed": after["Passed"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, default=ROOT)
    parser.add_argument("--wolfram", default="wolfram.exe")
    parser.add_argument("--form", choices=["both", *ENTRIES], default="both")
    parser.add_argument("--timeout", type=float, default=180)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--captures", type=Path, help="Optional directory retaining full captures and kernel logs")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    forms = list(ENTRIES) if args.form == "both" else [args.form]
    executable = str(Path(args.wolfram).resolve()) if Path(args.wolfram).is_file() else args.wolfram
    output = args.output.resolve()
    captures = args.captures.resolve() if args.captures else None
    if captures:
        captures.mkdir(parents=True, exist_ok=True)
    tool_paths = {CAPTURE.name: CAPTURE, Path(__file__).name: Path(__file__)}
    tool_bytes = {name: path.read_bytes() for name, path in tool_paths.items()}
    tool_hashes = {name: hashlib.sha256(contents).hexdigest()
                   for name, contents in tool_bytes.items()}
    report = {"RecordedAt": datetime.now(timezone.utc).isoformat(),
              "Scope": "Exact package definitions, contexts, native builtin isolation, and load/reload checks; not exhaustive input or kernel-version validation.",
              "Normalization": "Only escaped source-directory strings in package definition InputForm are normalized.",
              "WolframExecutable": executable, "PerKernelTimeoutSeconds": args.timeout,
              "ToolSHA256": tool_hashes,
              "Sources": {}, "Captures": {}, "Comparisons": {}}
    passed = True
    with tempfile.TemporaryDirectory(prefix="asymptotic-native-definitions-") as temporary:
        work = Path(temporary)
        capture_snapshot = work / CAPTURE.name
        capture_snapshot.write_bytes(tool_bytes[CAPTURE.name])
        capture_paths = {CAPTURE.name: capture_snapshot}
        capture_hashes = {CAPTURE.name: tool_hashes[CAPTURE.name]}
        stable = (fingerprints_match(capture_paths, capture_hashes)
                  and fingerprints_match(tool_paths, tool_hashes))
        report["ToolImmutability"] = {
            "CaptureSnapshotSHA256": capture_hashes[CAPTURE.name],
            "CaptureSnapshotMatchedSource": stable}
        passed = passed and stable
        if captures:
            shutil.copyfile(capture_snapshot, captures / CAPTURE.name)
        source_paths, original_hashes, states = {}, {}, {}
        for label, root in [("Baseline", args.baseline.resolve()), ("Candidate", args.candidate.resolve())]:
            paths = inputs(root, forms)
            hashes = fingerprint(paths)
            source_paths[label], original_hashes[label] = paths, hashes
            snapshot = work / label
            for name, path in paths.items():
                target = snapshot / name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, target)
            snapshot_hashes = fingerprint({name: snapshot / name for name in paths})
            stable = hashes == snapshot_hashes == fingerprint(paths)
            passed = passed and stable
            report["Sources"][label] = {"Root": str(root), "SHA256": hashes, "SnapshotMatchedSource": stable}
            for form in forms:
                key = label + "-" + form
                destination = work / (key + ".json")
                env = dict(os.environ, ASYMPTOTIC_NATIVE_SOURCE=str(snapshot / ENTRIES[form]),
                           ASYMPTOTIC_NATIVE_OUTPUT=str(destination))
                command = [executable, "-noinit", "-script", str(capture_snapshot)]
                print("Capturing " + key + " ...", flush=True)
                try:
                    if not fingerprints_match(capture_paths, capture_hashes):
                        raise ValueError("Frozen native capture script changed during run")
                    run = subprocess.run(command, cwd=work, env=env, stdout=subprocess.PIPE,
                                         stderr=subprocess.STDOUT, timeout=args.timeout, check=False)
                    log = run.stdout.decode("utf-8", errors="replace")
                    state = json.loads(destination.read_text(encoding="utf-8-sig")) if destination.is_file() else None
                    ok = run.returncode == 0 and state is not None and state.get("Passed") is True
                    report["Captures"][key] = {"ExitCode": run.returncode, "Passed": ok, "KernelOutput": log}
                    if state is not None:
                        states[key] = state
                except (OSError, subprocess.TimeoutExpired, ValueError) as error:
                    log = str(error)
                    ok = False
                    report["Captures"][key] = {"Passed": False, "Error": log}
                passed = passed and ok
                if captures:
                    (captures / (key + ".log")).write_text(log, encoding="utf-8")
                    if destination.is_file():
                        shutil.copyfile(destination, captures / (key + ".json"))
            unchanged = hashes == fingerprint({name: snapshot / name for name in paths})
            report["Sources"][label]["SnapshotUnchangedDuringRun"] = unchanged
            passed = passed and unchanged
        for form in forms:
            keys = "Baseline-" + form, "Candidate-" + form
            if all(key in states for key in keys):
                comparison = compare(*(states[key] for key in keys))
                report["Comparisons"][form] = comparison
                passed = passed and comparison["Passed"]
            else:
                report["Comparisons"][form] = {"Passed": False, "Error": "Missing kernel capture"}
                passed = False
        for label in source_paths:
            unchanged = original_hashes[label] == fingerprint(source_paths[label])
            report["Sources"][label]["OriginalSourcesUnchangedDuringRun"] = unchanged
            passed = passed and unchanged
        snapshot_unchanged = fingerprints_match(capture_paths, capture_hashes)
        originals_unchanged = fingerprints_match(tool_paths, tool_hashes)
        report["ToolImmutability"].update({
            "CaptureSnapshotUnchangedDuringRun": snapshot_unchanged,
            "OriginalToolsUnchangedDuringRun": originals_unchanged})
        passed = passed and snapshot_unchanged and originals_unchanged
    report["Passed"] = bool(passed)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"Output": str(output), "Passed": report["Passed"]}))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
