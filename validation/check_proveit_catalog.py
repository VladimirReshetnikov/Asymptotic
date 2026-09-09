"""Read-only checks for the ProveIt article catalog and its evidence.

Run from any directory with ``python validation/check_proveit_catalog.py``.
``--source-root C:/ProveIt`` additionally checks the current original document
inventory and evidence, without executing Git, TeX, or a PDF extraction tool.
The JSON report distinguishes errors from missing files and pending rebuilds;
either makes the final exit status nonzero. PDF freshness uses the build
planner's existing byte, input, log, date, and upstream-mtime checks.
Published upstream receipts additionally bind PDFs, compile inputs, and three
successful pass logs by hash; page counts and Libertinus fonts are checked as
recorded metadata, without independently parsing or rendering the PDFs.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import html
import json
from pathlib import Path, PurePosixPath
import re
import sys
from typing import Any, Iterator
from urllib.parse import unquote, urlsplit

# Importing the existing read-only planner must not write bytecode artifacts.
sys.dont_write_bytecode = True
from build_proveit_pdfs import BuildError, plan_article
from vendor_proveit_articles import (
    DEFAULT_DESTINATION, VendorError, io_path, mask_tex,
    relative_name,
)


def evidence_items(value: Any) -> Iterator[Any]:
    """Include selection evidence, readingOrder, and the full preserved map."""
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "evidence":
                if isinstance(child, list):
                    yield from child
                else:
                    yield child
            else:
                yield from evidence_items(child)
    elif isinstance(value, list):
        for child in value:
            yield from evidence_items(child)


def without_fences(text: str) -> str:
    result, marker, length = [], None, 0
    for line in text.splitlines():
        fence = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if marker is None and fence:
            marker, length = fence[1][0], len(fence[1])
        elif marker is not None:
            if fence and fence[1][0] == marker and len(fence[1]) >= length and not fence[2].strip():
                marker = None
        else:
            result.append(line)
    return "\n".join(result)


def markdown_anchors(text: str) -> set[str]:
    text = without_fences(text)
    anchors = set(re.findall(r"\b(?:id|name)\s*=\s*[\"']([^\"']+)[\"']", text))
    seen: set[str] = set()
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = re.match(r"^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$", line)
        heading = match[1] if match else None
        if heading is None and index + 1 < len(lines) and line.strip() and re.fullmatch(r" {0,3}(?:=+|-+)\s*", lines[index + 1]):
            heading = line.strip()
        if heading is None:
            continue
        heading = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", heading)
        heading = re.sub(r"<[^>]*>", "", heading)
        heading = html.unescape(heading).replace("`", "").replace("*", "").replace("~", "")
        slug = re.sub(r"[^\w\-\s]", "", heading.lower())
        slug = re.sub(r"\s", "-", slug)
        candidate, suffix = slug, 0
        while candidate in seen:
            suffix += 1
            candidate = f"{slug}-{suffix}"
        seen.add(candidate)
        anchors.add(candidate)
    return anchors


def markdown_links(text: str) -> Iterator[str]:
    """The catalog uses inline links; also accept reference-style definitions."""
    text = without_fences(text)
    destination = r"(<[^>\n]+>|[^\s)]+)"
    for match in re.finditer(r"!?\[(?:[^\]\\]|\\.)*\]\(\s*" + destination + r"(?:\s+[^\n)]*)?\)", text):
        yield match[1].strip("<>")
    for match in re.finditer(r"^ {0,3}\[[^\]]+\]:\s*" + destination, text, re.MULTILINE):
        yield match[1].strip("<>")


class Audit:
    def __init__(self, root: Path, source_root: Path | None = None):
        self.root = root.resolve()
        self.source_root = source_root.resolve() if source_root is not None else None
        self.errors: list[dict[str, Any]] = []
        self.pending: list[dict[str, Any]] = []
        self.pending_keys: set[tuple[str, str]] = set()
        self.cache: dict[Path, str] = {}
        self.counts: Counter[str] = Counter({"verified_upstream_builds": 0})
        self.freshness: dict[str, Any] = {"preserve": 0, "skip": 0, "pending": 0, "plans": []}
        self.source_inventory: dict[str, Any] = {"checked": False}

    def error(self, check: str, message: str, **details: Any) -> None:
        self.errors.append({"check": check, "message": message, **details})

    def waiting(self, check: str, message: str, path: str = "", **details: Any) -> None:
        key = (check, path)
        if key not in self.pending_keys:
            self.pending_keys.add(key)
            self.pending.append({"check": check, "message": message, "path": path, **details})

    def name(self, value: Any, check: str) -> str | None:
        try:
            return relative_name(value)
        except (VendorError, TypeError) as exc:
            self.error(check, str(exc))
            return None

    def text(self, path: Path, purpose: str) -> str | None:
        if path in self.cache:
            return self.cache[path]
        try:
            self.cache[path] = io_path(path).read_text(encoding="utf-8")
            return self.cache[path]
        except FileNotFoundError:
            self.waiting("missing-file", "Required file is not yet present", str(path), purpose=purpose)
        except (OSError, UnicodeError) as exc:
            self.error(purpose, "Cannot read UTF-8 file", path=str(path), detail=str(exc))
        return None

    def load(self, name: str, required: bool = True) -> dict[str, Any] | None:
        path = self.root / name
        if not required and not io_path(path).exists():
            return None
        text = self.text(path, name)
        if text is None:
            return None
        try:
            value = json.loads(text)
            if not isinstance(value, dict):
                raise ValueError("Top-level JSON must be an object")
            return value
        except (ValueError, TypeError) as exc:
            self.error(name, "Invalid JSON document", detail=str(exc))
            return None

    def unique_paths(self, values: list[Any], check: str) -> set[str]:
        seen: dict[str, str] = {}
        for value in values:
            name = self.name(value, check)
            if name is None:
                continue
            key = name.casefold()
            if key in seen:
                self.error(check, "Duplicate or case-colliding path", path=name, previous=seen[key])
            seen[key] = name
        return set(seen.values())

    def file_exists(self, path: Path, purpose: str) -> bool:
        if io_path(path).is_file():
            return True
        self.waiting("missing-file", "Required file is not yet present", str(path), purpose=purpose)
        return False

    def verify_evidence(self, value: Any, label: str, docs: Path) -> None:
        for entry in evidence_items(value):
            self.counts[label + "_attempted"] += 1
            if not isinstance(entry, dict) or not {"path", "line"} <= entry.keys() or not ("source" in entry or "source_excerpt" in entry):
                self.error(label, "Malformed evidence entry; expected path, line, and source or source_excerpt")
                continue
            path = self.name(entry["path"], label)
            line = entry["line"]
            expected = entry.get("source_excerpt", entry.get("source"))
            if path is None:
                continue
            if type(line) is not int or line < 1 or not isinstance(expected, str) or not expected:
                self.error(label, "Evidence requires a positive line number and nonempty exact source text", path=path, line=line)
                continue
            if PurePosixPath(path).parts[0].casefold() == "archive" and docs == self.root / "docs":
                self.error(label, "Selected evidence refers to excluded archive material", path=path)
                continue
            text = self.text(docs / path, label)
            if text is None:
                continue
            source_lines = text.splitlines()
            count = len(expected.split("\n"))
            actual = "\n".join(source_lines[line - 1:line - 1 + count])
            if line > len(source_lines) or actual != expected:
                self.error(label, "Source-line evidence differs from the current file", path=path, line=line,
                           expected=expected, actual=actual)
            else:
                self.counts[label + "_verified"] += 1

    def selection(self, data: dict[str, Any]) -> tuple[set[str], set[str], set[str]]:
        articles, excluded = data.get("articles"), data.get("excluded_articles")
        if not isinstance(articles, list) or not isinstance(excluded, list) or not all(isinstance(a, dict) for a in articles + excluded):
            self.error("selection", "articles and excluded_articles must be lists of objects")
            return set(), set(), set()
        tex = self.unique_paths([a.get("tex") for a in articles], "selected-tex")
        pdf = self.unique_paths([a.get("pdf") or str(PurePosixPath(a.get("tex", "invalid")).with_suffix(".pdf")) for a in articles], "selected-pdf")
        exclusions = self.unique_paths([a.get("path") for a in excluded], "excluded-tex")
        overlap = {x.casefold() for x in tex} & {x.casefold() for x in exclusions}
        if overlap:
            self.error("selection", "Selected and excluded source paths overlap", paths=sorted(overlap))
        references = sum(a.get("role") == "reference-companion" for a in articles)
        scope = data.get("scope", {})
        actual = {"selected_articles": len(articles) - references, "reference_companions": references,
                  "reviewed_document_roots": len(articles) + len(excluded)}
        for key, count in actual.items():
            self.counts[key] = count
            if type(scope.get(key)) is not int or scope[key] != count:
                self.error("selection-counts", "Declared count differs from records", field=key, declared=scope.get(key), actual=count)
        self.counts["excluded_articles"] = len(excluded)
        self.counts["archived_exclusions"] = sum(PurePosixPath(p).parts[0].casefold() == "archive" for p in exclusions)
        if scope.get("archive_excluded") is not True:
            self.error("archive", "Selection must explicitly exclude archived material")
        for path in tex | pdf:
            if PurePosixPath(path).parts[0].casefold() == "archive":
                self.error("archive", "Archived file was selected", path=path)
            suffix = ".tex" if path in tex else ".pdf"
            if PurePosixPath(path).suffix.lower() != suffix:
                self.error("selection", "Unexpected selected file extension", path=path, expected=suffix)
            if self.file_exists(self.root / "docs" / path, "selected source/PDF pair"):
                self.counts["selected_files_present"] += 1
        for article in articles:
            if not isinstance(article.get("evidence"), list) or not article["evidence"]:
                self.error("selection-evidence", "Selected root has no evidence", path=article.get("tex"))
        if io_path(self.root / "docs" / "archive").exists():
            self.error("archive", "Excluded archive directory is present in vendored docs")
        return tex, pdf, exclusions

    def check_manifest(self, selection: dict[str, Any], manifest: dict[str, Any], builds: dict[str, Any], tex: set[str], pdf: set[str]) -> None:
        if manifest.get("schema_version") != 1:
            self.error("manifest", "Unsupported manifest schema")
        selection_hash = hashlib.sha256(io_path(self.root / "selection.json").read_bytes()).hexdigest()
        if manifest.get("selection_sha256") != selection_hash:
            self.error("manifest", "selection.json SHA-256 does not match manifest", actual=selection_hash, recorded=manifest.get("selection_sha256"))
        repository = manifest.get("source_repository", {})
        if repository.get("commit") != selection.get("commit") or repository.get("docs_root") != selection.get("docs_root"):
            self.error("manifest", "Selection commit/docs root differs from manifest provenance")
        if manifest.get("selection") != selection:
            self.error("manifest", "Embedded selection differs from selection.json")
        if manifest.get("dependency_closure_complete") is not True:
            self.error("manifest", "Dependency closure is not complete")
        articles, files = manifest.get("articles", []), manifest.get("files", [])
        if not isinstance(articles, list) or not isinstance(files, list):
            self.error("manifest", "articles and files must be lists")
            return
        manifest_tex = self.unique_paths([a.get("destination_tex") for a in articles], "manifest-tex")
        manifest_pdf = self.unique_paths([a.get("destination_pdf") for a in articles], "manifest-pdf")
        if manifest_tex != {"docs/" + p for p in tex} or manifest_pdf != {"docs/" + p for p in pdf}:
            self.error("manifest", "Manifest source/PDF sets differ from the selected pairs")
        destinations = self.unique_paths([f.get("destination") for f in files], "manifest-files")
        for name in destinations:
            if name.casefold().startswith("docs/archive/"):
                self.error("archive", "Manifest contains an archive dependency", path=name)
        if builds.get("schema_version") != 1 or not isinstance(builds.get("regenerated_pdfs"), dict):
            self.error("builds", "Unsupported builds.json schema")
            return
        for name in builds["regenerated_pdfs"]:
            if name not in manifest_pdf:
                self.error("builds", "Build receipt names an unselected PDF", path=name)
        originals = {f["destination"]: f for f in files}
        for article in articles:
            try:
                plan = plan_article(article, self.root, builds, originals, False)
            except BuildError as exc:
                plan = {"tex": article.get("destination_tex"), "pdf": article.get("destination_pdf"),
                        "action": "build", "reasons": [str(exc)]}
            except (OSError, VendorError, KeyError, TypeError, ValueError) as exc:
                self.error("freshness", "Cannot check article build plan", path=article.get("destination_tex"), detail=str(exc))
                plan = {"tex": article.get("destination_tex"), "pdf": article.get("destination_pdf"),
                        "action": "build", "reasons": ["Invalid or unreadable build provenance"]}
            self.freshness["plans"].append(plan)
            action = plan["action"]
            if action in {"skip", "preserve-upstream"}:
                self.freshness["skip" if action == "skip" else "preserve"] += 1
            else:
                self.freshness["pending"] += 1
                self.waiting("pdf-freshness", "PDF requires a build before final validation", str(plan.get("pdf")), reasons=plan.get("reasons", []))

    def catalog(self) -> None:
        catalog = self.root / "README.md"
        text = self.text(catalog, "catalog")
        if text is None:
            return
        for target in markdown_links(text):
            self.counts["catalog_links"] += 1
            parsed = urlsplit(html.unescape(target))
            if parsed.scheme or parsed.netloc:
                self.counts["external_links_skipped"] += 1
                continue
            path_text, fragment = unquote(parsed.path), unquote(parsed.fragment)
            if "\x00" in path_text or "\\" in path_text or path_text.startswith("/"):
                self.error("catalog-links", "Catalog link must use a relative local path", target=target)
                continue
            path = (catalog.parent / path_text).resolve() if path_text else catalog
            if not self.file_exists(path, "catalog link"):
                continue
            self.counts["local_links_verified"] += 1
            if not fragment:
                continue
            if match := re.fullmatch(r"L([1-9]\d*)(?:-L?([1-9]\d*))?", fragment):
                source = self.text(path, "catalog-line-anchor")
                end = int(match[2] or match[1])
                if source is not None and not (int(match[1]) <= end <= len(source.splitlines())):
                    self.error("catalog-anchor", "Line anchor lies outside the source file", target=target)
                elif source is not None:
                    self.counts["line_anchors_verified"] += 1
            elif path.suffix.lower() in {".md", ".markdown"}:
                source = self.text(path, "catalog-heading-anchor")
                if source is not None and fragment not in markdown_anchors(source):
                    self.error("catalog-anchor", "Markdown heading or explicit anchor does not exist", target=target)
                elif source is not None:
                    self.counts["heading_anchors_verified"] += 1
            elif path.suffix.lower() in {".html", ".htm", ".svg"}:
                source = self.text(path, "catalog-html-anchor")
                ids = set(re.findall(r"\b(?:id|name)\s*=\s*[\"']([^\"']+)[\"']", source or ""))
                if source is not None and fragment not in ids:
                    self.error("catalog-anchor", "Explicit local anchor does not exist", target=target)
                elif source is not None:
                    self.counts["explicit_anchors_verified"] += 1
            else:
                self.error("catalog-anchor", "Cannot validate this local fragment without an appropriate format parser", target=target)

    def recorded_hash(self, name: Any, digest: Any, prefix: str) -> bool:
        """Check one receipt-bound local file without executing a document tool."""
        path = self.name(name, "upstream-builds")
        if path is None:
            return False
        if path != name or not path.startswith(prefix):
            self.error("upstream-builds", "Receipt path must be canonical and inside its declared directory", path=name, prefix=prefix)
            return False
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            self.error("upstream-builds", "Receipt requires a lowercase SHA-256", path=path)
            return False
        target = self.root / path
        if not self.file_exists(target, "upstream build receipt"):
            return False
        try:
            actual = hashlib.sha256(io_path(target).read_bytes()).hexdigest()
        except OSError as exc:
            self.error("upstream-builds", "Cannot hash receipt file", path=path, detail=str(exc))
            return False
        if actual != digest:
            self.error("upstream-builds", "Receipt SHA-256 differs from current file", path=path, recorded=digest, actual=actual)
            return False
        return True

    def upstream_builds(self, manifest: dict[str, Any], selected_pdf: set[str]) -> None:
        """Validate published refresh receipts; unchanged upstream PDFs need none."""
        self.counts["verified_upstream_builds"] = 0
        data = self.load("upstream-builds.json", required=False)
        if data is None:
            if not io_path(self.root / "upstream-builds.json").exists():
                self.waiting("upstream-builds", "Published build receipts are not yet present", "upstream-builds.json")
            return
        before = len(self.errors)
        if type(data.get("schema_version")) is not int or data["schema_version"] != 1:
            self.error("upstream-builds", "Unsupported published build receipt schema")
        if data.get("repository_url") != "https://github.com/VladimirReshetnikov/ProveIt":
            self.error("upstream-builds", "Published receipts must identify the canonical ProveIt repository")
        articles = data.get("articles")
        if not isinstance(articles, dict):
            self.error("upstream-builds", "articles must be an object keyed by selected PDF path")
            return
        if type(data.get("article_count")) is not int or data["article_count"] != len(articles):
            self.error("upstream-builds", "article_count differs from the receipt mapping")
        self.unique_paths(list(articles), "upstream-builds")
        manifest_articles = manifest.get("articles")
        if not isinstance(manifest_articles, list) or not all(isinstance(a, dict) for a in manifest_articles):
            self.error("upstream-builds", "Cannot check compile dependencies without manifest article records")
            return
        declared = {a.get("destination_pdf"): a for a in manifest_articles if isinstance(a.get("destination_pdf"), str)}
        selected = {"docs/" + p for p in selected_pdf}
        global_valid = len(self.errors) == before
        for pdf, receipt in articles.items():
            valid = global_valid

            def require(condition: bool, message: str, **details: Any) -> bool:
                nonlocal valid
                if not condition:
                    valid = False
                    self.error("upstream-builds", message, pdf=pdf, **details)
                return condition

            if not require(pdf in selected and pdf in declared,
                           "Receipt names an unselected PDF"):
                continue
            if not require(isinstance(receipt, dict), "Article receipt must be an object"):
                continue
            valid = self.recorded_hash(pdf, receipt.get("pdf_sha256"), "docs/") and valid
            inputs = receipt.get("effective_inputs")
            dependencies = declared[pdf].get("dependencies")
            if require(isinstance(inputs, dict), "effective_inputs must map compile paths to hashes"):
                if require(isinstance(dependencies, list) and all(isinstance(p, str) for p in dependencies),
                           "Manifest compile dependencies must be a list of paths"):
                    expected = set(dependencies) | {declared[pdf].get("destination_tex")}
                    require(expected <= inputs.keys(), "Receipt omits declared compile dependencies",
                            missing=sorted(expected - inputs.keys(), key=str))
                paths_before = len(self.errors)
                self.unique_paths(list(inputs), "upstream-builds")
                valid = len(self.errors) == paths_before and valid
                for path, digest in inputs.items():
                    valid = self.recorded_hash(path, digest, "docs/") and valid
            passes = receipt.get("passes")
            if require(isinstance(passes, list) and len(passes) == 3, "Receipt requires exactly three build passes"):
                log_paths = []
                for number, entry in enumerate(passes, 1):
                    if not require(isinstance(entry, dict), "Build pass must be an object", pass_number=number):
                        continue
                    require(type(entry.get("pass")) is int and entry["pass"] == number
                            and type(entry.get("returncode")) is int and entry["returncode"] == 0
                            and entry.get("timed_out") is False,
                            "Build passes must be numbered 1, 2, 3 and finish successfully", pass_number=number)
                    valid = self.recorded_hash(entry.get("path"), entry.get("sha256"), "build-logs/") and valid
                    log_paths.append(entry.get("path"))
                paths_before = len(self.errors)
                self.unique_paths(log_paths, "upstream-builds")
                valid = len(self.errors) == paths_before and valid
            require(type(receipt.get("page_count")) is int and receipt["page_count"] > 0,
                    "Receipt must record a positive integer page count")
            fonts = receipt.get("fonts")
            require(isinstance(fonts, list) and bool(fonts)
                    and all(isinstance(f, dict) and isinstance(f.get("name"), str) for f in fonts)
                    and any("Libertinus" in f["name"] for f in fonts),
                    "Receipt must record a Libertinus font")
            versions = receipt.get("tool_versions")
            require(isinstance(versions, dict) and isinstance(versions.get("pdflatex"), str)
                    and bool(versions["pdflatex"].strip()), "Receipt must identify its pdflatex version")
            if valid:
                self.counts["verified_upstream_builds"] += 1

    def original_inventory(self, selection: dict[str, Any], expected: set[str]) -> Path | None:
        if self.source_root is None:
            return None
        docs_name = self.name(selection.get("docs_root"), "source-inventory")
        if docs_name is None:
            return None
        docs = self.source_root / docs_name
        if not io_path(docs).is_dir():
            self.waiting("source-inventory", "Original docs directory is absent", str(docs))
            return None
        roots = set()
        for path in io_path(docs).rglob("*.tex"):
            text = self.text(path, "source-inventory")
            if text is not None and re.search(r"\\documentclass\b", mask_tex(text)):
                roots.add(path.relative_to(io_path(docs)).as_posix())
        self.source_inventory = {"checked": True, "root": str(docs), "document_roots": len(roots),
                                 "scope": "Current filesystem inventory; not a Git or mathematical verification"}
        if roots != expected:
            self.error("source-inventory", "Original standalone roots differ from the reviewed selection/exclusion inventory",
                       unreviewed=sorted(roots - expected), absent=sorted(expected - roots))
        return docs

    def run(self) -> dict[str, Any]:
        selection = self.load("selection.json")
        manifest = self.load("manifest.json")
        builds = self.load("builds.json", required=False) or {"schema_version": 1, "regenerated_pdfs": {}}
        documents = {name: self.load(name) for name in ("q-reading-list.json", "combinatorial-reading-list.json")}
        if selection is not None:
            if not isinstance(selection.get("commit"), str) or not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", selection["commit"]):
                self.error("selection", "Source commit must be a full immutable object ID")
            tex, pdf, exclusions = self.selection(selection)
            docs = self.original_inventory(selection, tex | exclusions)
            self.verify_evidence(selection.get("articles", []), "selection_evidence", self.root / "docs")
            if docs is not None:
                self.verify_evidence(selection, "original_selection_evidence", docs)
            for name, data in documents.items():
                if data is None:
                    continue
                if not isinstance(data.get("readingOrder"), list) or not data["readingOrder"]:
                    self.error(name, "readingOrder must be a nonempty list")
                else:
                    for entry in data["readingOrder"]:
                        if not isinstance(entry, dict) or not all(isinstance(entry.get(k), str) and entry[k] for k in ("title", "scopeAndStatus")) or not isinstance(entry.get("evidence"), list) or not entry["evidence"]:
                            self.error(name, "Reading entry requires title, scopeAndStatus, and evidence")
                if "source_commit" in data and data["source_commit"] != selection.get("commit"):
                    self.error(name, "Reading-map source commit differs from selection")
                label = name.removesuffix(".json").replace("-", "_")
                self.verify_evidence(data, label, self.root / "docs")
                if docs is not None:
                    self.verify_evidence(data, "original_" + label, docs)
            if manifest is not None:
                self.check_manifest(selection, manifest, builds, tex, pdf)
                self.upstream_builds(manifest, pdf)
            else:
                self.freshness["pending"] = len(tex)
                self.waiting("pdf-freshness", "Build freshness awaits the vendor manifest", "manifest.json", articles=len(tex))
        self.catalog()
        return {"ok": not self.errors and not self.pending, "vendor_root": str(self.root),
                "source_commit": selection.get("commit") if selection else None,
                "counts": dict(sorted(self.counts.items())), "source_inventory": self.source_inventory,
                "freshness": self.freshness, "errors": self.errors, "pending": self.pending,
                "error_count": len(self.errors), "pending_count": len(self.pending),
                "read_only": True}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vendor-root", type=Path, default=DEFAULT_DESTINATION)
    parser.add_argument("--source-root", type=Path, help="Optional original ProveIt repository root; read-only current inventory check")
    args = parser.parse_args()
    audit = Audit(args.vendor_root, args.source_root)
    try:
        report = audit.run()
    except (OSError, ValueError, TypeError, KeyError, AttributeError, VendorError) as exc:
        audit.error("validator", "Cannot finish validation because an input is malformed or unreadable", detail=str(exc))
        report = {"ok": False, "vendor_root": str(audit.root), "errors": audit.errors,
                  "pending": audit.pending, "counts": dict(audit.counts), "freshness": audit.freshness,
                  "error_count": len(audit.errors), "pending_count": len(audit.pending), "read_only": True}
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
