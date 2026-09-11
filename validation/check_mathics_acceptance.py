"""Verify complete portable Mathics evidence against raw immutable Git blobs.

python validation/check_mathics_acceptance.py --receipts EXTRACTED_ARTIFACTS \
  --revision COMMIT --output validation/mathics-final-acceptance.json \
  --run-url https://github.com/OWNER/REPOSITORY/actions/runs/RUN_ID

The artifact directory must contain only the downloaded shard JSON files
(normally one mathics-results.json in each artifact subdirectory). This tool
does not run kernels, modify receipts, or infer GitHub workflow success. It
checks the complete portable suite on both layouts at one exact source state.
"""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SUITE = "validation/MathicsTests.wl"
RUNNER = "validation/run_mathics_tests.py"
REQUIREMENTS = "validation/requirements-mathics.txt"
ENTRY = "AsymptoticAnalysis.wl"
MODULAR_ENTRY = "src/Kernel/" + ENTRY
PREFIX = "ASYMPTOTIC_PORTABLE_"
CASE_PATTERN = re.compile(r'^portableTest\["([a-z0-9-]+)", "([a-z]+)",', re.MULTILINE)
DECLARATION_PATTERN = re.compile(r'^portableTest\[(?![a-z]+_String)', re.MULTILINE)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(body: bytes) -> str:
    return hashlib.sha256(body).hexdigest()


def reference_from_blobs(blobs: dict[str, bytes], revision: str) -> dict:
    required = {SUITE, RUNNER, REQUIREMENTS, ENTRY, MODULAR_ENTRY}
    require(required <= blobs.keys(), f"Reference lacks required files: {sorted(required - blobs.keys())}")
    suite = blobs[SUITE].decode("utf-8")
    pairs = CASE_PATTERN.findall(suite)
    unrecognized = [number for number, line in enumerate(suite.splitlines(), 1)
                    if DECLARATION_PATTERN.match(line) and not CASE_PATTERN.match(line)]
    require(not unrecognized, f"Reference suite has unrecognized portableTest declarations at lines {unrecognized}")
    require(bool(pairs) and len(pairs) == len(dict(pairs)), "Reference suite has absent or duplicate test IDs")
    budgets = re.findall(r"\$IterationLimit\s*=\s*([0-9]+)", suite)
    require(len(set(budgets)) == 1, "Reference suite needs one unambiguous explicit iteration budget")
    versions = re.findall(r"^Mathics3==([^\s]+)\s*$", blobs[REQUIREMENTS].decode("utf-8"), re.MULTILINE)
    require(len(versions) == 1, "Reference requirements must pin one Mathics3 version")
    hashes = {path: sha256(body) for path, body in blobs.items()}
    common = {name: hashes[name] for name in (SUITE, RUNNER)}
    modular = {name: digest for name, digest in hashes.items()
               if re.fullmatch(r"src/Kernel/[^/]+\.wl", name)}
    return {"Revision": revision, "FilesSHA256": hashes, "Cases": dict(pairs),
            "IterationLimit": int(budgets[0]), "MathicsVersion": versions[0],
            "ExpectedSources": {"modular": dict(common, **modular),
                                "standalone": dict(common, **{ENTRY: hashes[ENTRY]})}}


def git_reference(repository: Path, revision: str) -> dict:
    def git(*args: str) -> bytes:
        return subprocess.check_output(["git", "-C", str(repository), *args])
    commit = git("rev-parse", "--verify", revision + "^{commit}").decode("ascii").strip()
    names = git("ls-tree", "-r", "--name-only", "-z", commit, "--", "src/Kernel",
                ENTRY, SUITE, RUNNER, REQUIREMENTS).decode("utf-8").split("\0")
    selected = [name for name in names if name in {ENTRY, SUITE, RUNNER, REQUIREMENTS}
                or re.fullmatch(r"src/Kernel/[^/]+\.wl", name)]
    blobs = {name: git("cat-file", "blob", commit + ":" + name) for name in selected}
    return reference_from_blobs(blobs, commit)


def unique_object(pairs: list[tuple]) -> dict:
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON member: {key}")
        result[key] = value
    return result


def canonical_sources(raw: dict) -> dict[str, str]:
    require(isinstance(raw, dict), "TestedSourcesSHA256 must be an object")
    result = {}
    for name, digest in raw.items():
        require(isinstance(name, str) and isinstance(digest, str)
                and re.fullmatch(r"[0-9a-f]{64}", digest) is not None,
                f"Invalid source fingerprint: {name}")
        parts = name.replace("\\", "/").split("/")
        if len(parts) >= 2 and parts[-2] == "Kernel" and parts[-1].endswith(".wl"):
            canonical = "src/Kernel/" + parts[-1]
        elif len(parts) >= 2 and parts[-2] == "validation" and parts[-1] in {
                "MathicsTests.wl", "run_mathics_tests.py", "requirements-mathics.txt"}:
            canonical = "validation/" + parts[-1]
        elif parts[-1] == ENTRY:
            canonical = ENTRY
        else:
            raise ValueError(f"Unexpected fingerprinted input: {name}")
        require(canonical not in result, f"Duplicate canonical input: {canonical}")
        result[canonical] = digest
    return result


def protocol_fields(output: str, test_id: str) -> dict:
    require(isinstance(output, str), f"{test_id}: missing raw kernel output")
    lines = output.splitlines()

    def scalar(suffix: str) -> str:
        prefix = PREFIX + suffix + "\t"
        values = [line[len(prefix):] for line in lines if line.startswith(prefix)]
        require(len(values) == 1, f"{test_id}: missing or duplicate {suffix} protocol field")
        return values[0]

    def block(field: str) -> str:
        first, last = PREFIX + field.upper() + "_BEGIN", PREFIX + field.upper() + "_END"
        require(lines.count(first) == lines.count(last) == 1, f"{test_id}: incomplete {field} protocol block")
        start, end = lines.index(first), lines.index(last)
        require(start < end, f"{test_id}: reversed {field} protocol block")
        return "\n".join(lines[start + 1:end])

    require(scalar("RESULT") == test_id + "\tSuccess", f"{test_id}: raw result is not its successful record")
    limit = scalar("ITERATION_LIMIT")
    require(limit.isdigit(), f"{test_id}: invalid iteration limit")
    return {"Kernel": scalar("KERNEL"), "KernelIterationLimit": int(limit),
            "ActualOutput": block("Actual"), "ExpectedOutput": block("Expected")}


def display_path(path: Path, repository: Path) -> str:
    try:
        return path.resolve().relative_to(repository.resolve()).as_posix()
    except ValueError:
        return str(path.resolve())


def validate_shard(report: dict, reference: dict) -> dict:
    require(report.get("Runtime") == "Mathics", "Receipt runtime is not Mathics")
    for key in ("RunComplete", "SourcesUnchangedDuringRun", "FreshKernelPerCase"):
        require(report.get(key) is True, f"Receipt requires {key}=true")
    results = report.get("Results")
    require(isinstance(results, list) and bool(results), "Receipt has no case results")
    for key in ("Selected", "Executed", "Succeeded", "Failed", "NotRun"):
        require(type(report.get(key)) is int, f"Invalid counter: {key}")
        expected = 0 if key in {"Failed", "NotRun"} else len(results)
        require(report[key] == expected, f"Incomplete or inconsistent counter: {key}")
    source = report.get("Source")
    require(isinstance(source, str), "Receipt has no source entry")
    parts = source.replace("\\", "/").split("/")
    require(parts[-1] == ENTRY, "Unexpected package entry filename")
    layout = "modular" if len(parts) >= 2 and parts[-2] == "Kernel" else "standalone"
    # A receipt that records a first observed source mismatch contradicts its
    # own source-stability claim even when the content was later restored
    # (wave-5 report 39 N03). The selected entry's membership among the
    # fingerprinted inputs is established by the exact reference-set
    # comparison below, which names every expected input of the layout.
    require(report.get("FirstObservedSourceDriftSHA256") is None,
            "A recorded first source mismatch contradicts the source-stability claim")
    sources = canonical_sources(report.get("TestedSourcesSHA256"))
    requirements_checks = []
    if REQUIREMENTS in sources:
        requirements_checks.append(sources.pop(REQUIREMENTS))
    if "RequirementsSHA256" in report:
        requirements_checks.append(report["RequirementsSHA256"])
    require(all(value == reference["FilesSHA256"][REQUIREMENTS] for value in requirements_checks),
            "Recorded requirements hash differs from reference")
    require(sources == reference["ExpectedSources"][layout],
            f"{layout}: exact source set or hashes differ from reference")
    if "SourcesSHA256AfterRun" in report:
        require(canonical_sources(report["SourcesSHA256AfterRun"]) ==
                canonical_sources(report["TestedSourcesSHA256"]), "Contradictory after-run source fingerprints")
    require(report.get("TestSuiteSnapshotSHA256") == reference["FilesSHA256"][SUITE],
            "Suite snapshot hash differs from reference")
    require(report.get("MathicsIterationLimitConfiguredBySuite") == reference["IterationLimit"],
            "Configured iteration budget differs from reference")
    seen = []
    kernels = set()
    for row in results:
        require(isinstance(row, dict), "Case result must be an object")
        test_id = row.get("TestID")
        require(test_id in reference["Cases"], f"Unexpected test ID: {test_id}")
        require(row.get("Group") == reference["Cases"][test_id], f"{test_id}: incorrect group")
        require(row.get("Outcome") == "Success" and type(row.get("ExitCode")) is int
                and row["ExitCode"] == 0, f"{test_id}: unsuccessful outcome or exit status")
        parsed = protocol_fields(row.get("KernelOutput"), test_id)
        require(all(row.get(key) == value for key, value in parsed.items()),
                f"{test_id}: stored fields disagree with raw kernel protocol")
        require(parsed["Kernel"].startswith("Mathics3 " + reference["MathicsVersion"] + " "),
                f"{test_id}: unexpected kernel or Mathics version")
        require(parsed["KernelIterationLimit"] == reference["IterationLimit"],
                f"{test_id}: effective iteration budget differs from reference")
        require(parsed["ActualOutput"] == parsed["ExpectedOutput"],
                f"{test_id}: successful SameQ assertion has inconsistent printed values")
        seen.append(test_id)
        kernels.add(parsed["Kernel"])
    require(len(seen) == len(set(seen)), "Duplicate test ID within a shard")
    return {"Layout": layout, "Cases": seen, "Groups": dict(Counter(reference["Cases"][name] for name in seen)),
            "Kernels": sorted(kernels), "RequirementsHashStatus": "Verified" if requirements_checks else "NotRecorded",
            "SourcesSHA256": sources, "TestSuiteSnapshotSHA256": report["TestSuiteSnapshotSHA256"]}


def verify_acceptance(paths: list[Path], reference: dict, repository: Path = ROOT) -> dict:
    require(bool(paths), "No JSON shard receipts found")
    require(len(paths) == len({path.resolve() for path in paths}), "Duplicate receipt path")
    receipts, raw_inputs = [], []
    counts = {"modular": Counter(), "standalone": Counter()}
    for path in paths:
        raw = path.read_bytes()
        try:
            shard = validate_shard(json.loads(raw, object_pairs_hook=unique_object), reference)
        except (ValueError, KeyError, TypeError) as error:
            raise ValueError(f"{path}: {error}") from error
        counts[shard["Layout"]].update(shard["Cases"])
        shard.update(Receipt=display_path(path, repository), ReceiptSHA256=sha256(raw))
        receipts.append(shard)
        raw_inputs.append((path, raw))
    expected = Counter({name: 1 for name in reference["Cases"]})
    for layout, observed in counts.items():
        require(observed == expected, f"{layout}: missing IDs {sorted((expected - observed).elements())}; "
                f"duplicate IDs {sorted((observed - expected).elements())}")
    require(all(path.read_bytes() == raw for path, raw in raw_inputs), "Receipt bytes changed during verification")
    return {"SchemaVersion": 1, "Accepted": True,
            "Scope": "Complete maintained portable Mathics suite on both package layouts at the exact reference source hashes; not the original MUnit suite or all possible inputs.",
            "ReferenceRevision": reference["Revision"], "ReferenceFilesSHA256": reference["FilesSHA256"],
            "CasesPerLayout": len(reference["Cases"]), "SuccessfulObservations": 2 * len(reference["Cases"]),
            "GroupsPerLayout": dict(Counter(reference["Cases"].values())),
            "RequirementsEvidence": dict(Counter(shard["RequirementsHashStatus"] for shard in receipts)),
            "RequirementsNote": "Verified checks the requirements input file hash, not installed packages. NotRecorded means that input hash is absent from the receipt. Observed kernel strings record runtime versions separately.",
            "ReceiptBytesUnchanged": True, "Receipts": receipts}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--receipts", type=Path, required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--repository", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--run-url", help="Caller-supplied workflow URL; GitHub status is not queried")
    args = parser.parse_args()
    paths = sorted(args.receipts.rglob("*.json"))
    if args.output.resolve() in {path.resolve() for path in paths}:
        parser.error("Output must not overwrite an input receipt")
    try:
        reference = git_reference(args.repository.resolve(), args.revision)
        result = verify_acceptance(paths, reference, args.repository)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Acceptance rejected: {error}\n")
    result["VerifiedUTC"] = datetime.now(timezone.utc).isoformat()
    if args.run_url:
        result["WorkflowRun"] = {"URL": args.run_url, "Provenance": "Caller supplied; workflow status not queried"}
        match = re.search(r"/actions/runs/([0-9]+)/?$", args.run_url)
        if match:
            result["WorkflowRun"]["ID"] = match[1]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes((json.dumps(result, indent=2) + "\n").encode("utf-8"))
    print(json.dumps({"Accepted": True, "Revision": result["ReferenceRevision"],
                      "CasesPerLayout": result["CasesPerLayout"], "Output": str(args.output)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
