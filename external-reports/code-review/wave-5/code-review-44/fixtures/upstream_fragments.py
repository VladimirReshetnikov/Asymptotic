"""Manually transcribed source fragments; not a complete repository checkout.

Origin: VladimirReshetnikov/Asymptotic at
8e859961d7d37f008b826f3a8cad406460271614.
Functions reconcile, write_json, recorder_inputs, receipt_matches retain their
fetched bodies. Imports and small dependency adapters are supplied here.
The sync_publish_fragment function packages the exact mkstemp/write/replace
sequence from sync_article; it omits that function's validation stages.
See article and NOTICE.md for scope. No Wolfram/Mathics code is executed here.
"""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import tempfile
from typing import Any
import uuid

class BuildError(RuntimeError):
    pass
class VendorError(RuntimeError):
    pass

def io_path(path: Path) -> Path:
    """Fixture adapter: ordinary POSIX paths, not upstream Windows io_path."""
    return path

def destination_file(root: Path, name: str) -> Path:
    """Fixture adapter for known safe, relative fixture names only."""
    candidate = (root / name).resolve()
    if not candidate.is_relative_to(root.resolve()):
        raise VendorError(name)
    return candidate

def digest(path: Path) -> str:
    with io_path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

# validation/summarize_mathics_tests.py :: reconcile
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

# validation/build_proveit_pdfs.py :: write_json
def write_json(path: Path, value: Any) -> None:
    target = io_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + "." + uuid.uuid4().hex[:8] + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(target)

# validation/build_proveit_pdfs.py :: receipt_matches
def receipt_matches(receipt: Any, inputs: dict[str, str], root: Path, pdf: str,
                    original_hash: str | None) -> bool:
    if not isinstance(receipt, dict) or "original_upstream_sha256" not in receipt or receipt["original_upstream_sha256"] != original_hash:
        return False
    recorded = receipt.get("source_inputs", {})
    if not isinstance(recorded, dict) or any(recorded.get(k) != v for k, v in inputs.items()):
        return False
    logs = receipt.get("pass_logs", [])
    if not isinstance(logs, list) or len(logs) != 3 or not isinstance(receipt.get("tool_versions"), dict) or not receipt["tool_versions"]:
        return False
    for number, entry in enumerate(logs, 1):
        if not isinstance(entry, dict) or type(entry.get("pass")) is not int or entry["pass"] != number:
            return False
        if type(entry.get("returncode")) is not int or entry["returncode"] != 0 or entry.get("timed_out") is not False:
            return False
    pdf_check = receipt.get("pdf_check")
    if not isinstance(pdf_check, dict) or type(pdf_check.get("page_count")) is not int or pdf_check["page_count"] <= 0:
        return False
    if not isinstance(pdf_check.get("validator"), str) or not pdf_check["validator"].strip():
        return False
    if receipt.get("status") != "three passes and basic PDF validation succeeded":
        return False
    try:
        if len({entry["path"] for entry in logs}) != 3:
            return False
        checked = [*recorded.items(), *((entry["path"], entry["sha256"]) for entry in logs),
                   (pdf, receipt["sha256"])]
        return all(digest(destination_file(root, name)) == value for name, value in checked)
    except (OSError, KeyError, TypeError, VendorError):
        return False

# validation/build_proveit_pdfs.py :: recorder_inputs
def recorder_inputs(path: Path, mirror: Path, cwd: Path) -> dict[str, Any]:
    """Record actual TeX inputs separately from the conservative manifest closure."""
    local, runtime = set(), set()
    if not path.is_file():
        raise BuildError("pdflatex did not produce the required recorder file")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.startswith("INPUT "):
            continue
        item = Path(line[6:].strip('"'))
        item = (item if item.is_absolute() else cwd / item).resolve()
        if not item.is_file():
            continue
        if item.is_relative_to(mirror / "docs"):
            local.add(item.relative_to(mirror).as_posix())
        elif not item.is_relative_to(mirror):
            runtime.add(str(item))
    return {"vendored_inputs": sorted(local),
            "runtime_inputs": [{"path": name, "sha256": digest(Path(name))} for name in sorted(runtime)]}

# validation/sync_proveit_pdfs.py :: sync_article publication subsequence
# Wrapper arguments/return are fixture-specific; operations are transcribed.
def sync_publish_fragment(target: Path, data: bytes) -> None:
    descriptor, name = tempfile.mkstemp(prefix=".proveit-pdf-", suffix=".tmp", dir=target.parent)
    temporary = Path(name)
    with os.fdopen(descriptor, "wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, target)
