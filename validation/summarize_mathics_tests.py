"""Summarize immutable portable receipts without replacing their recorded outcomes.

Example (run from the repository root):
  python validation/summarize_mathics_tests.py \
    --reconcile validation/mathics-modular-tests.json validation/mathics-modular-normalization-tests.json \
    --reconcile validation/mathics-standalone-tests.json validation/mathics-standalone-normalization-tests.json \
    --supplemental validation/mathics-modular-api-tests.json \
    --supplemental validation/mathics-standalone-api-tests.json \
    --supplemental validation/mathics-modular-final-api-tests.json \
    --supplemental validation/mathics-standalone-final-tests.json \
    --supplemental validation/mathics-modular-refinement-tests.json \
    --output validation/mathics-test-coverage.json

A reconciliation requires identical package hashes and successful reruns of
every originally failing case. It never changes the original full-run counts.
Supplemental batches keep separate source fingerprints. The resulting union
of successful cases is evidence across snapshots, not one full-current run.
Receipt file hashes normalize CRLF to LF so they survive Git publication.
Recorded package and test-suite byte hashes remain unchanged.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def package_hashes(report: dict) -> dict[str, str]:
    hashes = {}
    for path, digest in report["TestedSourcesSHA256"].items():
        normalized = path.replace("\\", "/")
        parts = normalized.split("/")
        if len(parts) >= 2 and parts[-2] == "Kernel":
            key = "src/Kernel/" + parts[-1]
        elif normalized.rsplit("/", 1)[-1] == "AsymptoticAnalysis.wl":
            key = "AsymptoticAnalysis.wl"
        else:
            continue
        if key in hashes and hashes[key] != digest:
            raise ValueError(f"Conflicting package fingerprints for {key}")
        hashes[key] = digest
    if not hashes:
        raise ValueError("Receipt has no package source fingerprints")
    return dict(sorted(hashes.items()))


def read_receipt(path: Path) -> dict:
    body = path.read_bytes()
    report = json.loads(body)
    if report["Runtime"] != "Mathics" or not report["RunComplete"] or not report["SourcesUnchangedDuringRun"]:
        raise ValueError(f"Incomplete, drifting, or non-Mathics receipt: {path}")
    results = report["Results"]
    ids = [result["TestID"] for result in results]
    successes = [result["TestID"] for result in results if result["Outcome"] == "Success"]
    failures = [result["TestID"] for result in results if result["Outcome"] != "Success"]
    if (len(ids) != len(set(ids)) or report["Selected"] != report["Executed"]
            or report["Executed"] != len(ids) or report["NotRun"] != 0
            or report["Succeeded"] != len(successes) or report["Failed"] != len(failures)):
        raise ValueError(f"Inconsistent receipt counters: {path}")
    sources = package_hashes(report)
    try:
        display_path = path.resolve().relative_to(Path.cwd()).as_posix()
    except ValueError:
        display_path = str(path.resolve())
    return {
        "Receipt": display_path,
        "ReceiptSHA256": hashlib.sha256(body.replace(b"\r\n", b"\n")).hexdigest(),
        "ReceiptSHA256Normalization": "CRLF-to-LF; all other bytes unchanged",
        "UTC": report["UTC"],
        "Source": report["Source"],
        "PackageLayout": "modular" if any(key.startswith("src/Kernel/") for key in sources) else "standalone",
        "PackageSourcesSHA256": sources,
        "PackageFingerprintSHA256": hashlib.sha256(json.dumps(sources, sort_keys=True).encode()).hexdigest(),
        "TestSuiteSnapshotSHA256": report["TestSuiteSnapshotSHA256"],
        "RunComplete": True,
        "SourcesUnchangedDuringRun": True,
        "OriginalCounts": {key: report[key] for key in ("Selected", "Executed", "Succeeded", "Failed", "NotRun")},
        "SuccessfulTestIDs": successes,
        "FailedTestIDs": failures,
    }


def reconcile(full: dict, correction: dict) -> dict:
    if full["PackageSourcesSHA256"] != correction["PackageSourcesSHA256"]:
        raise ValueError("Cannot reconcile results from different package sources")
    unresolved = set(full["FailedTestIDs"]) - set(correction["SuccessfulTestIDs"])
    if correction["FailedTestIDs"] or unresolved:
        raise ValueError(f"Correction did not resolve every original failure: {sorted(unresolved)}")
    return {
        "FullReceipt": full["Receipt"],
        "CorrectionReceipt": correction["Receipt"],
        "PackageLayout": full["PackageLayout"],
        "PackageFingerprintSHA256": full["PackageFingerprintSHA256"],
        "OriginalFullRunCounts": full["OriginalCounts"],
        "OriginalFailedTestIDsRetained": full["FailedTestIDs"],
        "CorrectedTestIDs": sorted(set(full["FailedTestIDs"]) & set(correction["SuccessfulTestIDs"])),
        "UniqueSuccessfulCasesAfterCorrection": len(set(full["SuccessfulTestIDs"]) | set(correction["SuccessfulTestIDs"])),
        "SamePackageSources": True,
        "OriginalReceiptOutcomesModified": False,
        "Reason": "Targeted reruns pass the previously failing case IDs on identical package source fingerprints; original full-run outcomes are retained.",
    }


def build_summary(pairs: list[tuple[dict, dict]], supplemental: list[dict]) -> dict:
    receipts = [receipt for pair in pairs for receipt in pair] + supplemental
    reconciliations = [reconcile(*pair) for pair in pairs]
    all_ids = sorted({test_id for receipt in receipts for test_id in receipt["SuccessfulTestIDs"]})
    by_layout = {}
    for layout in ("modular", "standalone"):
        selected = [receipt for receipt in receipts if receipt["PackageLayout"] == layout]
        by_layout[layout] = {
            "UniqueCasesWithSuccessfulEvidence": len({test_id for receipt in selected for test_id in receipt["SuccessfulTestIDs"]}),
            "DistinctPackageSnapshots": len({receipt["PackageFingerprintSHA256"] for receipt in selected}),
        }
    return {
        "SchemaVersion": 2,
        "Scope": "Portable case evidence across the explicitly fingerprinted snapshots; not a single final-source full run or the complete original MUnit suite.",
        "SingleFullCurrentSourceAcceptanceClaimed": False,
        "OriginalReceiptsPreserved": True,
        "UniqueCasesWithSuccessfulEvidenceAcrossRecordedSnapshots": len(all_ids),
        "SuccessfulTestIDsAcrossRecordedSnapshots": all_ids,
        "EvidenceByLayout": by_layout,
        "Reconciliations": reconciliations,
        "SupplementalReceipts": [receipt["Receipt"] for receipt in supplemental],
        "SupplementalFailedObservations": [{"Receipt": receipt["Receipt"], "TestID": test_id}
                                           for receipt in supplemental for test_id in receipt["FailedTestIDs"]],
        "Receipts": receipts,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reconcile", nargs=2, action="append", default=[], metavar=("FULL", "CORRECTION"))
    parser.add_argument("--supplemental", action="append", default=[])
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    inputs = [Path(path).resolve() for pair in args.reconcile for path in pair]
    inputs += [Path(path).resolve() for path in args.supplemental]
    if args.output.resolve() in inputs:
        parser.error("Output must not overwrite an input receipt")
    pairs = [(read_receipt(Path(full)), read_receipt(Path(correction))) for full, correction in args.reconcile]
    supplemental = [read_receipt(Path(path)) for path in args.supplemental]
    if not pairs and not supplemental:
        parser.error("Provide at least one reconciliation or supplemental receipt")
    summary = build_summary(pairs, supplemental)
    args.output.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"Output": str(args.output), "EvidenceByLayout": summary["EvidenceByLayout"]}))


if __name__ == "__main__":
    main()
