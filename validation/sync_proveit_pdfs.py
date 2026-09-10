"""Audit, or explicitly copy, completed vendored PDFs back to matching ProveIt sources.

By default this command only prints a JSON audit. --apply enables atomic PDF
replacement after per-article receipt, effective-input, and destination checks.
It never edits TeX, runs a document engine, or invokes Git. Articles with pending
repairs, missing inputs, source drift, or unexpected PDFs are individually skipped.

  python validation/sync_proveit_pdfs.py --source-root C:/ProveIt
  python validation/sync_proveit_pdfs.py --source-root C:/ProveIt --apply --output sync.json
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import stat
from pathlib import Path
import re
import sys
import tempfile
from typing import Any

from build_proveit_pdfs import receipt_matches
from proveit_build_patches import prepare_patches
from vendor_proveit_articles import DEFAULT_DESTINATION, VendorError, destination_file, io_path, relative_name


TEXT_EXTENSIONS = {".tex", ".sty", ".cls", ".bib", ".bst", ".def", ".cfg", ".clo",
                   ".fd", ".txt", ".csv", ".tsv", ".json", ".yaml", ".yml", ".md", ".rst"}


class SyncError(RuntimeError):
    pass


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    result = json.loads(io_path(path).read_bytes())
    if not isinstance(result, dict) or result.get("schema_version") != 1:
        raise SyncError(f"Unsupported JSON schema: {path}")
    return result


def source_path(source: Path, docs: str, name: str) -> Path:
    name = relative_name(name)
    if not name.startswith("docs/"):
        raise SyncError(f"Compile inputs and PDFs must be docs-relative: {name}")
    target = destination_file(source, docs + "/" + name[5:])
    if not target.resolve().is_relative_to(io_path(source).resolve()):
        raise SyncError(f"Source path escapes the explicit source root: {name}")
    return target


def read_stable(path: Path) -> tuple[bytes | None, tuple[int, ...] | None]:
    """Notice replacement or modification while reading, including same-size edits."""
    try:
        before = path.stat()
    except FileNotFoundError:
        return None, None
    data = path.read_bytes()
    after = path.stat()
    fields = ("st_dev", "st_ino", "st_size", "st_mtime_ns", "st_ctime_ns")
    first = tuple(getattr(before, name) for name in fields)
    second = tuple(getattr(after, name) for name in fields)
    if first != second or len(data) != after.st_size:
        raise SyncError(f"File changed while being read: {path}")
    return data, second


def previous_syncs(paths: list[Path], source: Path, docs: str) -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    """Read explicit prior apply ledgers; unsuccessful records grant no permission."""
    accepted: dict[str, list[dict[str, Any]]] = {}
    ledgers = []
    for path in paths:
        path = path.resolve()
        data, _ = read_stable(io_path(path))
        if data is None:
            raise SyncError(f"Previous sync ledger is missing: {path}")
        ledger = json.loads(data)
        if (not isinstance(ledger, dict) or type(ledger.get("schema_version")) is not int or
                ledger["schema_version"] != 1 or ledger.get("mode") != "apply" or
                not isinstance(ledger.get("articles"), list)):
            raise SyncError(f"Previous sync ledger must use the apply-result schema: {path}")
        recorded_root = ledger.get("source_root")
        if (not isinstance(recorded_root, str) or not Path(recorded_root).is_absolute() or
                io_path(Path(recorded_root)).resolve() != io_path(source).resolve()):
            raise SyncError(f"Previous sync source root does not match the explicit source root: {path}")
        ledger_hash, count = digest(data), 0
        for index, item in enumerate(ledger["articles"]):
            if not isinstance(item, dict):
                raise SyncError(f"Malformed article record in previous sync ledger: {path}")
            if item.get("status") not in {"copied", "already_current"}:
                continue
            pdf, value = item.get("pdf"), item.get("resulting_upstream_sha256")
            if (not isinstance(pdf, str) or relative_name(pdf) != pdf or not pdf.startswith("docs/") or
                    not pdf.endswith(".pdf") or item.get("upstream_pdf") != docs + "/" + pdf[5:] or
                    item.get("upstream_pdf_checked") is not True or not isinstance(value, str) or
                    re.fullmatch(r"[0-9a-f]{64}", value) is None or item.get("receipt_pdf_sha256") != value):
                raise SyncError(f"Invalid successful PDF path/hash record in previous sync ledger: {path}, article {index}")
            accepted.setdefault(pdf, []).append({"ledger_path": str(path), "ledger_sha256": ledger_hash,
                "article_index": index, "status": item["status"], "upstream_pdf": item["upstream_pdf"], "sha256": value})
            count += 1
        ledgers.append({"path": str(path), "sha256": ledger_hash, "accepted_records": count,
                        "ignored_unsuccessful_records": len(ledger["articles"]) - count})
    return accepted, ledgers


def equivalent_input(name: str, actual: bytes, expected: bytes) -> str | None:
    if actual == expected:
        return "exact"
    if Path(name).suffix.lower() not in TEXT_EXTENSIONS or b"\0" in actual or b"\0" in expected:
        return None
    try:
        actual.decode("utf-8")
        expected.decode("utf-8")
    except UnicodeDecodeError:
        return None
    if actual.replace(b"\r\n", b"\n") == expected.replace(b"\r\n", b"\n"):
        return "CRLF/LF only"
    return None


def validated_inputs(article: dict[str, Any], receipt: dict[str, Any], manifest: dict[str, Any],
                     vendor: Path, originals: dict[str, Any]) -> dict[str, bytes]:
    """Validate one receipt without depending on other articles' build progress."""
    pdf = article["destination_pdf"]
    recorded = receipt.get("source_inputs")
    required = set(article["dependencies"]) | {article["destination_tex"]}
    if not isinstance(recorded, dict) or not required.issubset(recorded):
        raise SyncError("Receipt does not cover every declared compile input")
    inputs = {}
    docs = relative_name(manifest["source_repository"]["docs_root"])
    for name, expected_hash in recorded.items():
        relative_name(name)
        original = originals.get(name)
        if (not name.startswith("docs/") or original is None or
                original["source_path"] != docs + "/" + name[5:] or original["sha256"] != expected_hash):
            raise SyncError(f"Receipt input does not match original manifest provenance: {name}")
        data, _ = read_stable(destination_file(vendor, name))
        if data is None or digest(data) != expected_hash:
            raise SyncError(f"Vendored compile input changed or is missing: {name}")
        inputs[name] = data
    original_hash = originals.get(pdf, {}).get("sha256")
    if (receipt.get("source_commit") != manifest["source_repository"]["commit"] or
            not receipt_matches(receipt, recorded, vendor, pdf, original_hash)):
        raise SyncError("Current PDF, source inputs, successful pass logs, or receipt provenance failed validation")
    patched, evidence = prepare_patches(article, lambda name: destination_file(vendor, name).read_bytes())
    if receipt.get("source_patches", {}) != evidence:
        raise SyncError("Article source repairs differ from its completed build receipt")
    inputs.update(patched)
    return inputs


def match_upstream(inputs: dict[str, bytes], source: Path, docs: str) -> list[dict[str, Any]]:
    evidence = []
    for name, expected in sorted(inputs.items()):
        path = source_path(source, docs, name)
        actual, _ = read_stable(path)
        if actual is None:
            raise SyncError(f"Upstream compile input is missing: {name}")
        match = equivalent_input(name, actual, expected)
        if match is None:
            raise SyncError(f"Upstream compile input drifted: {name}; actual={digest(actual)}, effective={digest(expected)}")
        evidence.append({"path": docs + "/" + name[5:], "effective_sha256": digest(expected),
                         "upstream_sha256": digest(actual), "match": match})
    return evidence


def sync_article(article: dict[str, Any], receipt: Any, manifest: dict[str, Any], vendor: Path,
                 source: Path, originals: dict[str, Any], apply: bool,
                 prior_sync: dict[str, list[dict[str, Any]]] | None = None) -> dict[str, Any]:
    pdf = article["destination_pdf"]
    docs = relative_name(manifest["source_repository"]["docs_root"])
    result: dict[str, Any] = {"pdf": pdf, "upstream_pdf": docs + "/" + pdf[5:], "status": "skipped",
                              "previous_upstream_sha256": None, "resulting_upstream_sha256": None,
                              "upstream_pdf_checked": False}
    temporary: Path | None = None
    try:
        if not pdf.endswith(".pdf"):
            raise SyncError("Selected PDF destination must have a .pdf extension")
        target = source_path(source, docs, pdf)
        before, token = read_stable(target)
        previous = None if before is None else digest(before)
        result.update(previous_upstream_sha256=previous, resulting_upstream_sha256=previous,
                      upstream_pdf_checked=True,
                      receipt_pdf_sha256=receipt.get("sha256") if isinstance(receipt, dict) else None,
                      original_upstream_sha256=originals.get(pdf, {}).get("sha256"))
        if not isinstance(receipt, dict):
            raise SyncError("No completed build receipt")
        inputs = validated_inputs(article, receipt, manifest, vendor, originals)
        result["compile_inputs"] = match_upstream(inputs, source, docs)
        original_hash = originals.get(pdf, {}).get("sha256")
        prior_evidence = [item for item in (prior_sync or {}).get(pdf, []) if item["sha256"] == previous]
        if previous not in {original_hash, receipt["sha256"]}:
            if not prior_evidence:
                raise SyncError("Upstream PDF matches neither the original snapshot, the current receipt, nor a successful previous sync")
            result["previous_sync_evidence"] = prior_evidence
        if previous is None and article.get("source_pdf") is not None:
            raise SyncError("An originally present upstream PDF was removed")
        result["source_patches"] = receipt.get("source_patches", {})
        if previous == receipt["sha256"]:
            result.update(status="already_current", reason="Upstream PDF already matches the validated receipt")
            return result
        if not apply:
            result.update(status="would_copy", planned_upstream_sha256=receipt["sha256"],
                          reason="Effective inputs and original destination match; --apply is required")
            return result
        data, _ = read_stable(destination_file(vendor, pdf))
        if data is None or digest(data) != receipt["sha256"]:
            raise SyncError("Vendored PDF changed before copying")
        # The parent already exists because the article's source input was checked.
        descriptor, name = tempfile.mkstemp(prefix=".proveit-pdf-", suffix=".tmp", dir=target.parent)
        temporary = Path(name)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        current = load_json(vendor / "builds.json")["regenerated_pdfs"].get(pdf)
        if (load_json(vendor / "manifest.json") != manifest or current != receipt or
                validated_inputs(article, receipt, manifest, vendor, originals) != inputs):
            raise SyncError("Build receipt or effective compile inputs changed before replacement")
        result["compile_inputs"] = match_upstream(inputs, source, docs)
        for evidence in result.get("previous_sync_evidence", []):
            ledger, _ = read_stable(io_path(Path(evidence["ledger_path"])))
            if ledger is None or digest(ledger) != evidence["ledger_sha256"]:
                raise SyncError("Previous sync ledger changed before replacement")
        current_pdf, current_token = read_stable(target)
        if current_token != token or current_pdf != before:
            raise SyncError("Upstream PDF changed concurrently; replacement was skipped")
        # Atomic replacement adopts the temporary file's permissions. On POSIX,
        # carry the existing target's access mode over so a 0644 or 0664 PDF
        # is not republished with the temporary file's restrictive default
        # (wave-5 report 44 T02). Windows ACLs are not modelled.
        if os.name != "nt" and target.is_file() and not target.is_symlink():
            os.chmod(temporary, stat.S_IMODE(target.stat().st_mode))
        os.replace(temporary, target)
        temporary = None
        result.update(status="changed_after_copy", resulting_upstream_sha256=None)
        copied, _ = read_stable(target)
        resulting = None if copied is None else digest(copied)
        result["resulting_upstream_sha256"] = resulting
        if resulting != receipt["sha256"]:
            result.update(status="changed_after_copy", reason="Destination changed after atomic replacement; review required")
        else:
            result.update(status="copied", reason="Validated PDF atomically copied after effective-input and destination rechecks")
    except (SyncError, VendorError, OSError, ValueError, KeyError, TypeError) as error:
        result["reason"] = str(error)
    finally:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError as error:
                result["temporary_cleanup_error"] = str(error)
    return result


def synchronize(vendor: Path, source: Path, apply: bool = False, queries: list[str] | None = None,
                previous: list[Path] | None = None) -> dict[str, Any]:
    vendor, source = vendor.resolve(), source.resolve()
    if vendor == source or vendor.is_relative_to(source) or source.is_relative_to(vendor):
        raise SyncError("Vendor and upstream source roots must be separate directory trees")
    manifest = load_json(vendor / "manifest.json")
    manifest_hash = digest(io_path(vendor / "manifest.json").read_bytes())
    builds = load_json(vendor / "builds.json")
    if not isinstance(builds.get("regenerated_pdfs"), dict):
        raise SyncError("builds.json must contain regenerated_pdfs")
    prior_sync, ledger_evidence = previous_syncs(previous or [], source,
                                               relative_name(manifest["source_repository"]["docs_root"]))
    originals = {item["destination"]: item for item in manifest["files"]}
    articles = manifest["articles"]
    if queries:
        articles = [article for article in articles if any(query.casefold() in
                    (article["destination_pdf"] + " " + article["destination_tex"]).casefold() for query in queries)]
    if not articles:
        raise SyncError("No selected articles match the requested filter")
    results = [sync_article(article, builds["regenerated_pdfs"].get(article["destination_pdf"]),
                           manifest, vendor, source, originals, apply, prior_sync) for article in articles]
    return {"schema_version": 1, "created_at": datetime.now(timezone.utc).isoformat(),
            "mode": "apply" if apply else "dry_run", "vendor_root": str(vendor), "source_root": str(source),
            "source_snapshot_commit": manifest["source_repository"]["commit"],
            "manifest_sha256": manifest_hash,
            "previous_sync_ledgers": ledger_evidence,
            "counts": {status: sum(item["status"] == status for item in results)
                       for status in ("copied", "would_copy", "already_current", "skipped", "changed_after_copy")},
            "articles": results, "git_invoked": False,
            "concurrency_scope": "Each article's receipt, effective inputs, and previous PDF are rechecked immediately before atomic replacement; no repository-wide transaction is claimed."}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--vendor-root", type=Path, default=DEFAULT_DESTINATION)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--dry-run", action="store_true", help="Explicit form of the read-only default")
    parser.add_argument("--article", action="append", help="Optional substring filter; repeat to include more articles")
    parser.add_argument("--previous-sync", type=Path, action="append", default=[],
                        help="Prior successful --apply JSON ledger; repeat to authorize earlier published PDF hashes")
    parser.add_argument("--output", type=Path, help="Also save the JSON audit to this file")
    options = parser.parse_args()
    if options.output and any(options.output.resolve() == path.resolve() for path in options.previous_sync):
        raise SyncError("Output must not overwrite a previous sync evidence ledger")
    result = synchronize(options.vendor_root, options.source_root, options.apply, options.article, options.previous_sync)
    encoded = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if options.output:
        io_path(options.output.absolute()).write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    if result["counts"]["changed_after_copy"]:
        raise SystemExit(1)


if __name__ == "__main__":
    try:
        main()
    except (SyncError, VendorError, OSError, ValueError, KeyError, TypeError) as error:
        print(f"PDF synchronization failed: {error}", file=sys.stderr)
        raise SystemExit(1)
